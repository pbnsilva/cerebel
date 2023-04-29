import os
import re
import json
import scrapy
from scrapers.items import Product
from dateutil import parser as date_parser
from urllib.parse import urljoin
from cerebel.lang.matcher import ColorMatcher
from html.parser import HTMLParser
from html import unescape


SIZE_OPTIONS = {
    'x-small', 'small', 'medium', 'large', 'x-large',
    'xs', 's', 's/m', 'm', 'm/l', 'l', 'xl',
}

color_matcher = ColorMatcher(os.path.join(os.getenv('DATA_PATH'), 'models', 'lang', 'colors.dat'))


class FaerSpider(scrapy.Spider):
    def __init__(self, *a, **kw):
        super(FaerSpider, self).__init__(*a, **kw)
        self._errors = []

    def raise_exception(self, error):
        self._errors.append(error)

        # TODO uncomment once we're better at detecting variant options
        # raise Exception(error)

    def closed(self, reason):
        pass

    def _alert_post_errors(self):
        # TODO collect and email
        print('There were errors scraping the brand %s, please check the logs' % self.name)


class ShopifySpider(FaerSpider):
    def __init__(self, *a, **kw):
        super(ShopifySpider, self).__init__(*a, **kw)

        if not hasattr(self, 'currency'):
            raise Exception('"currency" is not set')

        if not hasattr(self, 'max_pages'):
            raise Exception('"max_pages" is not set')

        self._do_extract_name = self._extract_name
        if hasattr(self, 'extract_name') and callable(getattr(self, 'extract_name')):
            self._do_extract_name = self.extract_name

        self._do_extract_description = self._extract_description
        if hasattr(self, 'extract_description') and callable(getattr(self, 'extract_description')):
            self._do_extract_description = self.extract_description

        self._do_extract_description_html = self._extract_description_html
        if hasattr(self, 'extract_description_html') and callable(getattr(self, 'extract_description_html')):
            self._do_extract_description_html = self.extract_description_html

        self._filter_product = None
        if hasattr(self, 'filter_product') and callable(getattr(self, 'filter_product')):
            self._filter_product = self.filter_product

        self._update_product = None
        if hasattr(self, 'update_product') and callable(getattr(self, 'update_product')):
            self._update_product = self.update_product

        self._do_filter_tags = self._filter_tags
        if hasattr(self, 'filter_tags') and callable(getattr(self, 'filter_tags')):
            self._do_filter_tags = self.filter_tags

        self._do_filter_images = self._filter_images
        if hasattr(self, 'filter_images') and callable(getattr(self, 'filter_images')):
            self._do_filter_images = self.filter_images

        self._product_ids = set()

    def start_requests(self):
        for url in self.collection_urls:
            for i in range(1, self.max_pages + 1):
                yield scrapy.Request(url['value'] + '?page=' + str(i), callback=self.parse_collection_page, meta={'gender': url['gender']})

    def parse_collection_page(self, response):
        data = json.loads(response.body_as_unicode())
        for prod in data['products']:
            if prod['id'] in self._product_ids:
                continue
            self._product_ids.add(prod['id'])

            try:
                yield self.parse_product(response, prod)
            except Exception as ex:
                self.raise_exception(str(ex))

    def parse_product(self, response, prod):
        p = Product()
        p['created_at'] = int(date_parser.parse(prod['created_at']).timestamp())
        p['vendor_id'] = str(prod['id'])
        p['brand'] = self.name
        p['url'] = self._url_format(response.url, prod)
        p['name'] = self._do_extract_name(prod['title'])
        p['image_url'] = self._do_filter_images([img['src'] for img in prod['images']])
        p['description'] = self._do_extract_description(prod['body_html'])
        p['description_html'] = self._do_extract_description_html(prod['body_html'])
        p['gender'] = response.meta['gender']
        p['currency'] = self.currency.lower()
        p['price'] = float(prod['variants'][0]['price'])
        p['original_price'] = self.get_original_price(prod['variants'][0])
        p['tags'] = self._do_filter_tags(p.get('tags', []) + prod['tags'])

        if self._filter_product and not self._filter_product(p):
            return

        if self._update_product:
            self._update_product(p)

        p['variants'] = self.get_variants(prod)
        if hasattr(self, 'label_finder_urls'):
            p['label_finder_urls'] = self.label_finder_urls

        return p

    def get_variants(self, product):
        variants = []
        for v in product['variants']:
            v = self._process_variant(v)
            if v:
                variants.append(v)
        return variants

    def _process_variant(self, variant):
        # this happens when there is only one variant
        if variant['option1'].lower() in {'default title', 'one size'}:
            return

        result = {'vendor_id': variant['id'], 'vendor_sku': variant['sku'], 'name': variant['title'], 'available': variant['available']}

        for opt_field in {'option1', 'option2'}:
            if not variant[opt_field]:
                continue

            if self._is_size(variant[opt_field]):
                result['size'] = variant[opt_field].lower()
            elif self._is_color(variant[opt_field]):
                result['color'] = variant[opt_field].lower()
            # else:
            #    raise Exception('unknown variant option "%s"' % variant[opt_field])

        return result

    def _is_size(self, option):
        opt = option.lower()
        return opt in SIZE_OPTIONS or opt.isdigit()

    def _is_color(self, option):
        return len(color_matcher.match(option)) > 0

    def _url_format(self, response_url, product):
        url = urljoin(response_url.rsplit('/', 1)[0] + '/products/', product['handle'])
        if hasattr(self, 'utm_source') and self.utm_source:
            url += '?utm_source=' + self.utm_source
        return url

    def get_original_price(self, variant):
        if variant['compare_at_price'] is None or float(variant['compare_at_price']) == 0.0:
            return
        return float(variant['compare_at_price'])

    def _extract_description(self, body_html):
        body = HTMLUtil.to_formatted_text(body_html)
        return body

    def _extract_description_html(self, body_html):
        return HTMLUtil.from_formatted_text(self._do_extract_description(body_html))

    def _extract_name(self, name):
        return name

    def _filter_tags(self, tags):
        return tags

    def _filter_images(self, urls):
        return urls


class SquarespaceSpider(scrapy.Spider):
    def __init__(self, *a, **kw):
        super(SquarespaceSpider, self).__init__(*a, **kw)

        if not hasattr(self, 'max_pages'):
            raise Exception('"max_pages" is not set')

        self._do_extract_name = self._extract_name
        if hasattr(self, 'extract_name') and callable(getattr(self, 'extract_name')):
            self._do_extract_name = self.extract_name

        self._do_extract_description = self._extract_description
        if hasattr(self, 'extract_description') and callable(getattr(self, 'extract_description')):
            self._do_extract_description = self.extract_description

        self._do_extract_description_html = self._extract_description_html
        if hasattr(self, 'extract_description_html') and callable(getattr(self, 'extract_description_html')):
            self._do_extract_description_html = self.extract_description_html

        self._filter_product = None
        if hasattr(self, 'filter_product') and callable(getattr(self, 'filter_product')):
            self._filter_product = self.filter_product

        self._update_product = None
        if hasattr(self, 'update_product') and callable(getattr(self, 'update_product')):
            self._update_product = self.update_product

        self._do_filter_tags = self._filter_tags
        if hasattr(self, 'filter_tags') and callable(getattr(self, 'filter_tags')):
            self._do_filter_tags = self.filter_tags

        self._product_ids = set()

    def start_requests(self):
        for url in self.collection_urls:
            for i in range(1, self.max_pages + 1):
                yield scrapy.Request(url['value'] + '&page=' + str(i), callback=self.parse_collection_page, meta={'gender': url['gender'], 'dont_redirect': True, 'handle_httpstatus_list': [302, 301]})

    def parse_collection_page(self, response):
        data = json.loads(response.body_as_unicode())
        for prod in data.get('items', []):
            if prod['id'] in self._product_ids:
                continue
            self._product_ids.add(prod['id'])
            p = Product()
            p['created_at'] = int(prod['addedOn']/1000)
            p['brand'] = self.name
            p['url'] = urljoin(response.url.rsplit('/', 1)[0], prod['fullUrl'])
            p['name'] = self._do_extract_name(prod['title'])
            p['image_url'] = [img['assetUrl'] for img in prod['items']]
            p['description'] = self._do_extract_description(prod['excerpt'])
            p['description_html'] = self._do_extract_description_html(prod['excerpt'])
            p['gender'] = response.meta['gender']

            variant = prod['variants'][0]
            p['currency'] = variant['priceMoney']['currency'].lower()
            if variant['onSale']:
                p['price'] = float(variant['salePriceMoney']['value'])
                p['original_price'] = float(variant['priceMoney']['value'])
            else:
                p['price'] = float(variant['priceMoney']['value'])

            p['tags'] = self._do_filter_tags(p.get('tags', []) + prod.get('tags', []) + prod.get('categories', []))

            if hasattr(self, 'label_finder_urls'):
                p['label_finder_urls'] = self.label_finder_urls

            if self._filter_product and not self._filter_product(p):
                return

            if self._update_product:
                self._update_product(p)

            yield p

    def _extract_description(self, body_html):
        body = HTMLUtil.to_formatted_text(body_html)
        return body

    def _filter_tags(self, tags):
        return tags

    def _extract_description_html(self, body_html):
        return HTMLUtil.from_formatted_text(self._do_extract_description(body_html))

    def _extract_name(self, name):
        return name


class HTMLUtil:
    script_sheet = re.compile(r"<(script|style).*?>.*?(</\1>)", re.IGNORECASE | re.DOTALL)
    # HTML comments - can contain ">"
    comment = re.compile(r"<!--(.*?)-->", re.DOTALL)
    # HTML tags: <any-text>
    tag = re.compile(r"<.*?>", re.DOTALL)
    # Consecutive whitespace characters
    nwhites = re.compile(r"[\s]+")
    # <p>, <div>, <br>, <li>, <span> tags and associated closing tags
    p_div = re.compile(r"</?(p|div|br|li|span).*?>", re.IGNORECASE | re.DOTALL)
    # Consecutive whitespace, but no newlines
    nspace = re.compile("[^\\S\n]+", re.UNICODE)
    # At least two consecutive newlines
    n2ret = re.compile("\n\n+")
    # A return followed by a space
    retspace = re.compile("(\n )")

    html_parser = HTMLParser()

    @staticmethod
    def to_formatted_text(html):
        """Remove all HTML tags, but produce a nicely formatted text."""
        if html is None:
            return ''
        text = HTMLUtil.script_sheet.sub("", html)
        text = HTMLUtil.comment.sub("", text)
        text = HTMLUtil.nwhites.sub(" ", text)
        text = HTMLUtil.p_div.sub("\n", text)  # convert <p>, <div>, <br> to "\n"
        text = HTMLUtil.tag.sub("", text)     # remove all tags
        text = unescape(text)
        # get whitespace right
        text = HTMLUtil.nspace.sub(" ", text)
        text = HTMLUtil.retspace.sub("\n", text)
        text = HTMLUtil.n2ret.sub("\n\n", text)
        text = text.strip()
        return text

    @staticmethod
    def from_formatted_text(text):
        """ Replace newlines with html line breaks """
        return text.replace('\n', '<br>')
