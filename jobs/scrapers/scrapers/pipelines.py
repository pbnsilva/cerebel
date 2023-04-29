# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: http://doc.scrapy.org/en/latest/topics/item-pipeline.html

import os
import six
import re
import imgix
import json
from lxml import html
import grpc
import requests
from PIL import Image, ImageChops
from html import unescape
from io import BytesIO
from datetime import datetime, timedelta
from dateutil import parser as date_parser
from dateutil import rrule
from elasticsearch import Elasticsearch
from elasticsearch.helpers import scan
from elasticsearch.exceptions import NotFoundError
from pyfcm import FCMNotification
from urllib.parse import unquote
from google.cloud import storage
from collections import defaultdict
from urllib.request import urlopen
from hashlib import sha1, sha256
from scrapy.exceptions import DropItem, CloseSpider
from scrapers import store_pb2, store_pb2_grpc
from scrapers import annotation_pb2, annotation_pb2_grpc
from slugify import slugify
from urllib.parse import urlparse
from google.cloud import translate


STORE_ID = 'faer'
ADMIN_TOKEN = 'PJYsxDjsgNOhWOwDENHjUzoYrOtlVv'
FCM_API_KEY = "AAAA1ux6mfA:APA91bEP2-rbqLkNJkBtL9v7ZPcHA2HJzI3jLEkulAHNBDz4vZDlMraEn1uttNiuQznHe2ti-dy0mPItsV0oHq3ip_BEEDLM7aQo1hOxODsVyhO3ykf4kNtjGiRkV61l4RIITwtSnALQ"

_BIG_QUERY_TABLE_NAME = 'analytics_163193596.events_'


class BrandPipeline:

    def __init__(self):
        self.es_host = os.getenv('ELASTIC_HOST', 'http://localhost:9200')
        self._env = os.getenv('ENV', 'dev')

    def open_spider(self, spider):
        if self._env == 'dev':
            return

        self.brand_id = sha1(spider.name.encode('utf-8')).hexdigest()

        es = Elasticsearch(self.es_host)

        if self._brand_page_exists(es, self.brand_id):
            return

        self._create_brand_page(es, self.brand_id, spider.name)

    def process_item(self, item, spider):
        if self._env == 'dev':
            return item

        item['brand_id'] = self.brand_id

        return item

    def _brand_page_exists(self, es, brand_id):
        try:
            es.get(index='brands', doc_type='item', id=brand_id)
        except NotFoundError:
            return False
        return True

    def _create_brand_page(self, es, brand_id, name):
        es.index(index='brands', doc_type='item', id=brand_id, body={'id': brand_id, 'name': name})


class MinimumRequirementsPipeline:
    """
    Checks if a product fills the minimum requirements; drops it if not.
    - Checks if the item has a set of mandatory fields;
    """
    def process_item(self, item, spider):
        if 'url' not in item or not item['url']:
            raise DropItem('Missing URL field')

        # make sure item has all the fields we need
        for f in {'name', 'image_url', 'brand', 'price', 'currency', 'gender', 'description'}:
            if f not in item or not item[f]:
                raise DropItem('Missing %s in item at URL: %s' % (f, item['url']))
            if isinstance(item[f], str) and not item[f].strip():
                raise DropItem('Missing %s in item at URL: %s' % (f, item['url']))

        # check that gender is a list (needed for proper mapping with the
        # store)
        if not isinstance(item['gender'], list):
            item['gender'] = [item['gender']]

        # some brands use the original_price field incorrectly
        if item.get('original_price') is not None:
            if item['price'] == item['original_price']:
                item['original_price'] = None

        item['description'] = unescape(item['description'])

        name_sp = set(item['name'].lower().split())
        if 'gift' in name_sp:
            raise DropItem('Found gift card')

        return item


class ItemIDPipeline:
    """
    Adds an `id` field to every scraped item.
    The ID is a hash of item URL.
    """

    def process_item(self, item, spider):
        if not item['url']:
            raise DropItem('Missing URL in %s' % item)
        item['id'] = self._get_hashed_url(item['url'])
        item['_ignore_pipeline'] = False
        return item

    def _get_hashed_url(self, url):
        return sha256(url.encode('utf8')).hexdigest()


class ExistingItemFilterPipeline:
    """
    Drops items that already exist in the store.
    """
    def __init__(self):
        self._env = os.getenv('ENV', 'dev')
        if self._env == 'dev':
            return

        self._brand_products = {}

        store_host = os.getenv('STORE_HOST', 'localhost:9090')
        store_channel = grpc.insecure_channel(store_host)
        self._store_stub = store_pb2_grpc.ProductStoreStub(store_channel)

    def open_spider(self, spider):
        if self._env == 'dev':
            return

        brand = spider.name
        if brand not in self._brand_products:
            self._brand_products[brand] = self._get_products_for_brand(brand)

    def process_item(self, item, spider):
        if self._env == 'dev':
            return item

        """
        # ---- TEST PN ----
        if item['id'] in {'b1ec271c44c90303695d1df959a2d2419ba6416a90578429f88d53fcb64913d2'}:
            original_price = item['price']
            item['price'] = 5.0
            item['original_price'] = original_price
        # -----------------
        """

        if item['id'] in self._brand_products[spider.name]:
            if not self._has_changes(spider.name, item):
                item['_ignore_pipeline'] = True
            elif item.get('original_price') and item['original_price'] > item['price']:
                item['_new_on_sale'] = True

        return item

    def _get_products_for_brand(self, brand):
        return {item.id: self._pb_to_json(item) for item in self._list_products(brand)}

    def _list_products(self, brand):
        items = self._store_stub.ListItemsForBrand(store_pb2.ListItemsForBrandRequest(store_id=STORE_ID,
                                                                                      brand=brand))
        for item in items:
            yield item

    # TODO this is not good, very hacky
    # we should be hashing, but some fields change later in the pipeline
    # (price, image_url, for example)
    def _has_changes(self, brand, item):
        cur_item = self._brand_products[brand][item['id']]
        if cur_item['description'] != item['description']:
            return True
        if cur_item['url'] != item['url']:
            return True
        if cur_item['name'] != item['name']:
            return True
        if cur_item['price'] != item['currency']:
            return True

        currency = item['currency'].lower()
        if abs(self._get_price_value(cur_item['price'], currency) - item['price']) > 0.05:
            return True
        if cur_item['original_price'] and item.get('original_price'):
            if self._get_price_value(cur_item['original_price'], currency) != item['original_price']:
                return True

        return False

    def _get_price_value(self, price_obj, currency):
        if currency == 'eur':
            return price_obj.eur
        elif currency == 'gbp':
            return price_obj.gbp
        elif currency == 'usd':
            return price_obj.usd
        elif currency == 'dkk':
            return price_obj.dkk
        elif currency == 'sek':
            return price_obj.sek
        elif currency == 'inr':
            return price_obj.inr
        elif currency == 'aud':
            return price_obj.aud

    def _pb_to_json(self, pb):
        item = {
            'id': pb.id,
            'created_at': pb.created_at,
            'brand': pb.brand,
            'description': pb.description,
            'gender': [v for v in pb.gender],
            'image_url': [v for v in pb.image_url],
            'name': pb.name,
            'price': pb.price,
            'original_price': pb.original_price,
            'url': pb.url,
        }
        return item


class CleanFieldsPipeline:
    """
    - Removes html tags and unescapes descriptions;
    - Limits number of images per product.
    """
    def process_item(self, item, spider):
        if item['_ignore_pipeline']:
            return item

        item['description'] = unescape(self.remove_html_tags(item['description'])).strip()
        item['image_url'] = item['image_url'][:5]

        return item

    def remove_html_tags(self, data):
        p = re.compile(r'<.*?>')
        return p.sub('', data)


class PricesPipeline:
    def __init__(self):
        self._accepted_currencies = {'eur', 'gbp', 'usd', 'dkk', 'sek', 'inr', 'aud'}
        try:
            self._exchange_rates = self._get_exchange_rates()
        except ErrorFetchingExchangeRates:
            self._exchange_rates = {
                'eur': 1.0,
                'gbp': 0.87,
                'usd': 1.13,
                'dkk': 7.46,
                'sek': 10.27,
                'inr': 81.45,
                'aud': 1.57,
            }

    """
    Adds `price[CUR]` field to the scraped item.
    """
    def process_item(self, item, spider):
        item['currency'] = item['currency'].lower()
        item['price'] = self._get_price(self._exchange_rates, item['price'], item['currency'])

        if item.get('original_price'):
            item['original_price'] = self._get_price(self._exchange_rates, item['original_price'], item['currency'])

            if item['original_price'][item['currency']] <= item['price'][item['currency']]:
                del item['original_price']

        return item

    def _get_price(self, eur_to, price, currency):
        # calculate eur
        # we're ok with losing some precision
        price = {currency: price}
        if currency != 'eur':
            price['eur'] = round(2 * price[currency] / eur_to[currency]) / 2

        # convert to all currencies
        for cur in eur_to:
            if cur.lower() in price:
                continue
            price[cur.lower()] = round(2 * eur_to[cur] * price['eur']) / 2

        return price

    def _get_exchange_rates(self):
        req = requests.get('http://data.fixer.io/api/latest?access_key=942c66ef9a2653a2108a03956c9e40c9&symbols=%s&base=EUR' % ','.join(self._accepted_currencies))
        if req.status_code != 200:
            raise ErrorFetchingExchangeRates

        resp = req.json()
        if not resp['success']:
            raise ErrorFetchingExchangeRates

        rates = resp['rates']
        return {k.lower(): v for k, v in rates.items()}


class TranslationPipeline:
    """
    Translates name and description if the spider has a translate_to attribute.
    """
    def __init__(self):
        self._translator = translate.Client()

    def process_item(self, item, spider):
        if item['_ignore_pipeline']:
            return item

        if os.getenv('ENV', 'dev') == 'dev':
            return item

        if not hasattr(spider, 'translate_to'):
            return item

        item['name'] = unescape(self._translator.translate(item['name'], spider.translate_to)['translatedText'])
        item['description'] = unescape(self._translator.translate(item['description'], spider.translate_to)['translatedText'])

        return item


class CoverImagePipeline:
    """
    Picks the best cover image for this product:
        - little or no white borders;
        - TODO: prioritize image with a face.
    """

    def __init__(self):
        pass

    def process_item(self, item, spider):
        if item['_ignore_pipeline']:
            return item

        if os.getenv('ENV', 'dev') == 'dev':
            return item

        best_border = None
        urls = item['image_url']
        for i, url in enumerate(urls):
            top_border = self._get_white_borders(url)[1]
            if best_border is None or best_border[1] > top_border:
                best_border = (i, top_border)

        idx = best_border[0]
        item['image_url'] = [urls[idx]] + urls[:idx] + urls[idx+1:]

        return item

    def _get_white_borders(self, url):
        try:
            req = requests.get(
                url,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36'
                },
                stream=True)
        except requests.exceptions.SSLError:
            req = requests.get(
                url,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36'
                },
                stream=True,
                verify=False)

        if req.status_code != 200:
            return

        src = Image.open(BytesIO(req.content))
        bg = Image.new(src.mode, src.size, (255, 255, 255))
        return ImageChops.difference(src, bg).getbbox()


class UploadImagesPipeline:
    """
    Uploads the images to GCS.
    If the images are too big, they are resized.
    If they need border trimming, that is done too.
    """

    def __init__(self):
        self._storage_client = storage.Client()
        self._bucket_name = 'assets.cerebel.io'
        self._max_side = 2000

    def process_item(self, item, spider):
        if item['_ignore_pipeline']:
            return item

        if os.getenv('ENV', 'dev') == 'dev':
            return item

        image_urls = []
        for i, url in enumerate(item['image_url']):
            buf = self._get_resized_buf(url, getattr(spider, 'trim_border', None))
            if not buf:
                continue

            filename = self._get_filename(item['id'], i + 1)
            content_type = 'image/jpeg'
            image_urls.append(self._upload_file(buf, filename, content_type))

        if not image_urls:
            raise DropItem('Missing image URLs in %s' % item)

        item['image_url'] = image_urls
        return item

    def _get_resized_buf(self, url, trim_border):
        try:
            req = requests.get(
                url,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36'
                },
                stream=True)
        except requests.exceptions.SSLError:
            req = requests.get(
                url,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36'
                },
                stream=True,
                verify=False)

        if req.status_code != 200:
            return

        src = Image.open(BytesIO(req.content))

        buf = BytesIO()

        if src.mode == 'RGBA':
            background = Image.new('RGB', src.size, (255, 255, 255))
            background.paste(src, mask=src.split()[3])
            src = background

        if trim_border:
            bg = Image.new(src.mode, src.size, (255, 255, 255))
            diff = ImageChops.difference(src, bg)
            bbox = diff.getbbox()
            if bbox:
                src = src.crop(bbox)

        w, h = src.size
        if w >= h:
            new_h = int(w / 0.7)
            new_src = Image.new('RGB', (w, new_h), (255, 255, 255))
            new_src.paste(src, (0, int((new_h - h) / 2)))
            src = new_src
            w, h = src.size

        if h > self._max_side:
            new_w = int(w * self._max_side / h)
            src = src.resize((new_w, self._max_side), Image.ANTIALIAS)

        if src.mode == 'P':
            src = src.convert('RGB')

        src.save(buf, 'JPEG', optimize=True, quality=70)

        return buf

    def _upload_file(self, file_stream, filename, content_type):
        """
        Uploads a file to a given Cloud Storage bucket and returns the public url
        to the new object.
        """
        bucket = self._storage_client.bucket(self._bucket_name)
        blob = bucket.blob(filename)

        blob.upload_from_string(
            file_stream.getvalue(),
            content_type=content_type)

        url = blob.public_url

        if isinstance(url, six.binary_type):
            url = url.decode('utf-8')

        return unquote(url)

    def _get_filename(self, image_id, ct):
        return 'images/faer/%s-%d.jpg' % (image_id, ct)


class ImgixImageProcessingPipeline:
    """
    This pipeline does smart cropping on the images and uploads them to
    google cloud storage.
    """

    def __init__(self):
        self._storage_client = storage.Client()
        self._bucket_name = 'assets.cerebel.io'
        self._url_builder = imgix.UrlBuilder("cerebel.imgix.net", sign_key="bxV45KHupc3vaDjr")

    def process_item(self, item, spider):
        if item['_ignore_pipeline']:
            return item

        if os.getenv('ENV', 'dev') == 'dev':
            return item

        if getattr(spider, 'use_imgix', None):
            image_urls = []
            for i, url in enumerate(item['image_url']):
                fstream = urlopen(self._get_imgix_url(url)).read()
                filename = self._get_filename(item['id'], i + 1)
                content_type = 'image/jpeg'
                image_urls.append(self._upload_file(fstream, filename, content_type))
            item['image_url'] = image_urls
        return item

    # TODO we're calling imgix, but could probably roll our own processing
    def _get_imgix_url(self, url):
        return self._url_builder.create_url(url, {'auto': 'compress', 'w': 831, 'h': 1800, 'fit': 'crop', 'crop': 'entropy'})

    def _upload_file(self, file_stream, filename, content_type):
        """
        Uploads a file to a given Cloud Storage bucket and returns the public url
        to the new object.
        """
        bucket = self._storage_client.bucket(self._bucket_name)
        blob = bucket.blob(filename)

        blob.upload_from_string(
            file_stream,
            content_type=content_type)

        url = blob.public_url

        if isinstance(url, six.binary_type):
            url = url.decode('utf-8')

        return unquote(url)

    def _get_filename(self, image_id, ct):
        return 'images/faer/%s-%d.jpg' % (image_id, ct)


class StoreLocationsPipeline:
    """
    This pipeline fetches store locations from label finder, then copies the store locations to a field that can be indexed.
    Expects a `label_finder_urls` or `stores` object in the request, with a `location` string field `lat, lon`.
    """
    def __init__(self):
        self._stores_cache = {}

    def process_item(self, item, spider):
        if item['_ignore_pipeline']:
            return item

        if item['brand'] in self._stores_cache:
            item['stores'] = self._stores_cache[item['brand']]
        elif 'label_finder_urls' in item:
            try:
                item['stores'] = self._fetch_stores(item['label_finder_urls'])
            except Exception as e:
                spider.logger.error('Error fetching stores from Label Finder: %s' % e)
            del item['label_finder_urls']

        if 'stores' not in item or not item['stores']:
            return item

        self._stores_cache[item['brand']] = item['stores']

        return item

    def _fetch_stores(self, finder_urls):
        stores = []
        for url in finder_urls:
            stores += self._parse_label_finder_url(url)
        return stores

    def _parse_label_finder_url(self, url):
        locations = []
        page_data = urlopen(url).read()
        root = html.fromstring(page_data)
        store_divs = root.xpath('//div[@itemtype="http://schema.org/ClothingStore"]')
        for tree in store_divs:
            store = {}
            store['name'] = tree.xpath('.//h3[@itemprop="name"]/text()')[0].strip()
            store['address'] = self._extract_street_address(tree)
            store['postal_code'] = tree.xpath('.//span[@itemprop="postalCode"]/text()')
            if not store['postal_code']:
                store['postal_code'] = 'N/A'
            else:
                store['postal_code'] = store['postal_code'][0].strip()
            store['city'] = tree.xpath('.//span[@itemprop="addressLocality"]/text()')[0].strip()
            store['country'] = self._extract_country(tree)
            store['location'] = {}
            store['location']['lat'] = float(tree.xpath('.//meta[@itemprop="latitude"]/@content')[0].strip())
            store['location']['lon'] = float(tree.xpath('.//meta[@itemprop="longitude"]/@content')[0].strip())
            locations.append(store)
        return locations

    def _extract_street_address(self, tree):
        address = tree.xpath('.//span[@itemprop="streetAddress"]/text()')[0].strip()
        if address == "":
            address = tree.xpath('.//span[@itemprop="streetAddress"]/span/text()')[0].strip()
        return address

    def _extract_country(self, tree):
        vals = tree.xpath('.//span[@class="hidden"]/text()')
        for v in vals:
            if v != 'Shop type':
                return v.replace(',', '').strip()
        return ''


class ProductImportPipeline:
    def __init__(self):
        self._env = os.getenv('ENV', 'dev')
        if self._env == 'dev':
            return

        self._brand_product_ids = {}
        self._insert_items = defaultdict(list)
        self._product_ids = defaultdict(set)
        self._bulk_size = 50
        self._found_items = defaultdict(int)
        store_host = os.getenv('STORE_HOST', 'localhost:9090')
        annotation_host = os.getenv('ANNOTATION_HOST', 'localhost:9092')

        store_channel = grpc.insecure_channel(store_host)
        self._store_stub = store_pb2_grpc.ProductStoreStub(store_channel)
        annotation_channel = grpc.insecure_channel(annotation_host)
        self._annotation_stub = annotation_pb2_grpc.AnnotatorStub(annotation_channel)
        self._grpc_metadata = [(str('x-cerebel-token'), str(ADMIN_TOKEN))]

    def open_spider(self, spider):
        if self._env == 'dev':
            return

        brand = spider.name
        if brand not in self._brand_product_ids:
            self._brand_product_ids[brand] = self._get_product_ids_for_brand(brand)

    def process_item(self, item, spider):
        if self._env == 'dev':
            return item

        if item['_ignore_pipeline']:
            return item

        brand = spider.name

        if item['id'] not in self._brand_product_ids[brand]:
            self._insert_items[brand].append(item)
        else:
            self._found_items[brand] += 1

        self._product_ids[brand].add(item['id'])

        return item

    def close_spider(self, spider):
        if self._env == 'dev':
            return

        for brand in self._brand_product_ids:
            spider.logger.info('Found %d products already in the store' % self._found_items[brand])

            for i in range(0, len(self._insert_items[brand]), self._bulk_size):
                insert_bulk = self._insert_items[brand][i:i+self._bulk_size]
                annotated_bulk = self._annotate_items(insert_bulk)
                self._store_stub.BulkUpsertItems(store_pb2.BulkUpsertItemsRequest(store_id=STORE_ID,
                                                                                  items=annotated_bulk),
                                                 metadata=self._grpc_metadata)
                spider.logger.info('Upserted %d products' % len(insert_bulk))

            delete_ids = []
            for item_id in self._brand_product_ids[brand]:
                if item_id not in self._product_ids[brand]:
                    delete_ids.append(item_id)

            for i in range(0, len(delete_ids), self._bulk_size):
                delete_bulk = delete_ids[i:i+self._bulk_size]
                self._store_stub.BulkDeleteItemsByID(store_pb2.BulkDeleteItemsByIDRequest(store_id=STORE_ID,
                                                                                          ids=delete_bulk),
                                                     metadata=self._grpc_metadata)
                spider.logger.info('Deleted %d products' % len(delete_bulk))

            abs_count = len(self._insert_items[brand]) - len(delete_ids) + self._found_items[brand]
            if abs_count == 0:
                self._alert_post_no_products(brand)

    def _annotate_items(self, items):
        annotated_bulk = []
        texts = []
        indices = []
        for item in items:
            item_texts = [item['name'], item['brand']]
            item_texts.extend(item['gender'])
            item_texts.extend(item.get('tags', []))
            item_indices = []
            for t in item_texts:
                item_indices.append(len(texts))
                texts.append(t)
            indices.append(item_indices)

        text_feature = annotation_pb2.TextFeature.Type.Value('ENTITY_PREDICTION')
        requests = [
            annotation_pb2.AnnotateTextRequest(text=doc,
                                               features=[annotation_pb2.TextFeature(type=text_feature)]) for doc in texts]

        annotations = self._annotation_stub.BatchAnnotateTexts(annotation_pb2.BatchAnnotateTextsRequest(requests=requests))

        for i, item in enumerate(items):
            labels = defaultdict(list)
            ents = set()
            for j in indices[i]:
                response = annotations.responses[j]
                for ent_an in response.entity_annotations:
                    if ent_an.label in ents:
                        continue

                    labels[ent_an.cls].append(ent_an.label)
                    ents.add(ent_an.label)

            item_annotations = []
            for k in labels:
                item_annotations.append(store_pb2.Annotation(kind=k, values=labels[k]))

                if k == 'color':
                    item_annotations.append(store_pb2.Annotation(kind='color_count', values=[str(len(labels[k]))]))

            annotated_bulk.append(self._to_pb_item(item, item_annotations))

        return annotated_bulk

    def _to_pb_item(self, d, annotations):
        price = store_pb2.Price(eur=d['price']['eur'],
                                gbp=d['price']['gbp'],
                                usd=d['price']['usd'],
                                dkk=d['price']['dkk'],
                                sek=d['price']['sek'],
                                inr=d['price']['inr'],
                                aud=d['price']['aud'])

        original_price = None
        if d.get('original_price') is not None:
            original_price = store_pb2.Price(eur=d['original_price']['eur'],
                                             gbp=d['original_price']['gbp'],
                                             usd=d['original_price']['usd'],
                                             dkk=d['original_price']['dkk'],
                                             sek=d['original_price']['sek'],
                                             inr=d['original_price']['inr'],
                                             aud=d['original_price']['aud'])
        stores = None
        if 'stores' in d:
            stores = [store_pb2.Store(name=s['name'],
                                      country=s['country'],
                                      city=s['city'],
                                      postal_code=s['postal_code'],
                                      location=store_pb2.Location(lon=s['location']['lon'], lat=s['location']['lat']),
                                      address=s['address']) for s in d['stores']]

        variants = None
        if 'variants' in d:
            variants = [store_pb2.Variant(vendor_id=str(s['vendor_id']),
                                          vendor_sku=s['vendor_sku'],
                                          name=s['name'],
                                          available=s['available'],
                                          image_url=s.get('image_url'),
                                          size=s.get('size'),
                                          color=s.get('color')) for s in d['variants']]

        item = store_pb2.Item(id=str(d['id']),
                              created_at=int(datetime.now().timestamp()),
                              vendor_id=d.get('vendor_id'),
                              name=d['name'],
                              brand=d['brand'],
                              brand_id=d['brand_id'],
                              url=d['url'],
                              share_url=d['share_url'],
                              gender=d['gender'],
                              description=d['description'],
                              image_url=d['image_url'],
                              tags=d.get('tags'),
                              price=price,
                              original_price=original_price,
                              stores=stores,
                              variants=variants,
                              annotations=annotations)

        return item

    def _get_product_ids_for_brand(self, brand):
        return set(item.id for item in self._list_products(brand))

    def _list_products(self, brand):
        items = self._store_stub.ListItemsForBrand(store_pb2.ListItemsForBrandRequest(store_id=STORE_ID,
                                                                                      brand=brand))
        for item in items:
            yield item

    def _alert_post_no_products(self, brand):
        # TODO collect and email
        print('NO PRODUCTS FOR BRAND %s' % brand)


class ProductLandingPagePipeline:
    def __init__(self):
        self._env = os.getenv('ENV', 'dev')
        if self._env == 'dev':
            return

        self._currency_symbol_map = {'gbp': '£', 'usd': '$', 'eur': '€'}

        self._storage_client = storage.Client()
        self._bucket_name = 'assets.cerebel.io'
        self._key_prefix = 'product_landing_pages'

        try:
            with open('templates/product_landing_page.html', 'r', encoding='utf-8') as f:
                self._template = f.read()
        except FileNotFoundError:
            raise CloseSpider(reason='product landing page template not found')

    def process_item(self, item, spider):
        if self._env == 'dev':
            return item

        if item['_ignore_pipeline']:
            return item

        name_slug = slugify(item['name'])
        brand_slug = slugify(item['brand'])
        product_slug = self._get_product_slug(name_slug, brand_slug)
        share_url = 'https://shop.wearefaer.com/%s' % product_slug

        page = self._get_landing_page(spider, item, self._template, share_url)
        self._upload_file(page, '%s/%s' % (self._key_prefix, product_slug), 'text/html')

        item['share_url'] = share_url

        return item

    def _get_product_slug(self, name_slug, brand_slug):
        # avoid duplicates
        slug = '%s-%s' % (name_slug, brand_slug)
        r = requests.head('https://shop.wearefaer.com/%s' % slug)
        if r.status_code == 200:
            for i in range(1, 10):
                slug = '%s-%s-%d' % (name_slug, brand_slug, i)
                r = requests.head('https://shop.wearefaer.com/%s' % slug)
                if r.status_code != 200:
                    break
        return slug

    def _get_landing_page(self, spider, item, template, share_url):
        return template.format(
            name=item['name'],
            short_description=item['description'][:300],
            description=self._get_description(item),
            keywords=','.join(self._get_keywords(item)),
            url=share_url,
            main_image_url=item['image_url'][0],
            product_id=item['id'],
            brand_name=item['brand'],
            price=self._get_price(item),
            source_url=item['url'],
            brand_url=self._get_brand_url(spider, item),
            currency_symbol=self._currency_symbol_map['eur'],
            images_container=self._get_images_container(item),
            ld_schema=json.dumps(self._get_ld_schema(item)))

    def _get_keywords(self, item):
        return item.get('tags', []) + [item['brand']]

    def _get_category(self, item):
        if item.get('tags'):
            return item['tags'][0]
        return ''

    def _get_brand_url(self, spider, item):
        if hasattr(spider, 'allowed_domains'):
            url = spider.allowed_domains[0]
            if not url.startswith('http'):
                url = 'https://' + url
            return url
        parsed = urlparse(item['url'])
        return '%s://%s/' % (parsed.scheme, parsed.netloc)

    def _get_description(self, item):
        if 'description_html' in item:
            return item['description_html']
        return '<br>'.join([v for v in item['description'].split('\n') if v.strip()])

    def _get_price(self, item):
        return item['price']['eur']

    def _get_ld_schema(self, item):
        return {
            "@context": "http://schema.org/",
            "@type": "Product",
            "name": item['name'],
            "image": json.dumps(item['image_url']),
            "description": item['description'],
            "sku": item['id'],
            "brand": {
                "@type": "Thing",
                "name": item['brand']
            },
            "offers": {
                "@type": "Offer",
                "category": self._get_category(item),
                "name": item['name'],
                "priceCurrency": item['currency'],
                "price": item['price'],
                "url": item['url'],
                "itemCondition": "http://schema.org/NewCondition",
                "availability": "http://schema.org/InStock"
            }
        }

    def _get_images_container(self, item):
        html = ''
        for url in item['image_url']:
            html += '<div><img alt="product image" src="%s"></div>' % url
        return html

    def _upload_file(self, file_content, filename, content_type):
        """
        Uploads a file to a given Cloud Storage bucket and returns the public url
        to the new object.
        """
        bucket = self._storage_client.bucket(self._bucket_name)
        blob = bucket.blob(filename)

        blob.upload_from_string(
            file_content,
            content_type=content_type)

        url = blob.public_url

        if isinstance(url, six.binary_type):
            url = url.decode('utf-8')

        return unquote(url)


class PushNotificationsPipeline:
    def __init__(self):
        self._env = os.getenv('ENV', 'dev')
        if self._env == 'dev':
            return

        self._fcm_service = FCMNotification(api_key=FCM_API_KEY)

        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = "/secret/faer-180421-firebase-adminsdk-2vsmn-6a05d90c4c.json"
        # self._bigquery_client = bigquery.Client(project='faer-180421')

        self._users = {}
        self._sales = {}

        # fetch users' tokens
        today = datetime.today().date()
        es_host = os.getenv('ELASTIC_HOST', 'http://localhost:9200')
        es = Elasticsearch(es_host)
        results = scan(es,
                       index="users",
                       doc_type="item",
                       preserve_order=True,
                       query={'query': {'exists': {'field': 'fcm_token'}}})
        for hit in results:
            src = hit['_source']
            if not src.get('os'):
                continue
            if src.get('last_notification_date') and today == date_parser.parse(src['last_notification_date']).date():
                continue
            self._users[src['id']] = {'id': src['id'], 'token': src['fcm_token'], 'os': src['os']}

    def open_spider(self, spider):
        if self._env == 'dev':
            return

        self._logger = spider.logger

    def process_item(self, item, spider):
        if self._env == 'dev':
            return item

        if item['_ignore_pipeline']:
            return item

        if not item.get('_new_on_sale', False):
            return

        # calculate discount
        item_discount = 100.0 * (item['original_price']['eur'] - item['price']['eur']) / item['original_price']['eur']
        if item_discount <= 0:  # shouldn't happen
            return

        self._sales[item['id']] = {'name': item['name'], 'discount': item_discount}

    def close_spider(self, spider):
        if self._env == 'dev':
            return

        if not self._sales:
            return

        ios_users = defaultdict(list)
        android_users = defaultdict(list)
        for user_id, product_id in self._query_users_wishlist(self._users.keys(), self._sales.keys()):
            u = self._users[user_id]
            if u['os'] == 'ios':
                ios_users[product_id].append(u)
            elif u['os'] == 'android':
                android_users[product_id].append(u)

        # use notification messages with iOS
        # iOS doesn't support handling data messages when app is in background
        for product_id in ios_users:
            item = self._sales[product_id]
            self._notify_users([u['token'] for u in ios_users[product_id]],
                               'Faer',
                               '%d%% off on %s!' % (int(item['discount']), item['name']),
                               {'product_id': product_id, 'topic': 'product_sale'})
            self._update_notification_dates(ios_users[product_id])

        # use data messages on Android
        for product_id in android_users:
            self._notify_users([u['token'] for u in android_users[product_id]],
                               None,
                               None,
                               {'product_id': product_id,
                                'topic': 'product_sale',
                                'title': 'Faer',
                                'body': '%d%% off on %s!' % (int(item['discount']), item['name'])})
            self._update_notification_dates(android_users[product_id])

    def _query_users_wishlist(self, user_ids, product_ids):
        date_range = []
        to_date = datetime.now()
        from_date = to_date - timedelta(days=120)
        for dt in rrule.rrule(rrule.MONTHLY, dtstart=from_date, until=to_date):
            date_range.append(dt.date().strftime('%Y%m%d'))

        q = '''
            SELECT
                user_pseudo_id,
                product_id,
                event_name
            FROM (%s)
            WHERE event_name="add_to_wishlist"
            AND user_pseudo_id IN (%s)
            AND product_id IN (%s)
            ''' % (' UNION ALL '.join(['SELECT user_pseudo_id, (SELECT e.value.string_value FROM UNNEST(event_params) as e WHERE e.key="item_id") as product_id, event_name FROM %s%s' % (_BIG_QUERY_TABLE_NAME, day) for day in date_range]),
                   ','.join(["'%s'" % u for u in user_ids]),
                   ','.join(["'%s'" % p for p in product_ids]))
        return [(r['user_pseudo_id'], r['product_id']) for r in self._bigquery_client.query(q)]

    def _notify_users(self, users, title, body, data):
        result = self._fcm_service.notify_multiple_devices(registration_ids=users,
                                                           message_title=title,
                                                           message_body=body,
                                                           data_message=data)
        self._logger.info('Successfully notified %d users (%d fails)' % (result['success'], result['failure']))
        for i, res in enumerate(result['results']):
            if 'error' in res:
                self._logger.error('Error notifying user with token "%s": %s' % (users[i], res['error']))

    def _update_notification_dates(self, users):
        cdate = datetime.now()
        url = 'https://api.cerebel.io/v3/store/faer/user/%s'
        for u in users:
            r = requests.put(url % u['id'],
                             data=json.dumps({'last_notification_date': cdate.strftime('%Y-%m-%dT%H:%M:%SZ%z')}),
                             headers={'X-Cerebel-Token': ADMIN_TOKEN})
            if r.status_code != 200:
                self._logger.error('Error updating notification dates for user "%s": %s' % (u['id'], r.text))


class ErrorFetchingExchangeRates(Exception):
    pass
