import json
import scrapy
from scrapers.items import Product
from bs4 import BeautifulSoup


class EverlaneSpider(scrapy.Spider):
    name = "Everlane"
    allowed_domains = ["everlane.com"]

    def __init__(self, *a, **kw):
        super(EverlaneSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.everlane.com"
        self.max_pages = 30
        # self._product_groups = {}
        # self._existing_groups = set()
        self._category_urls = [
            ['women', 'https://www.everlane.com/api/v2/collections/womens-jeans'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-tees'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-tops'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-sweaters'],
            ['women', 'https://www.everlane.com/api/v2/collections/dresses'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-bottoms'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-outerwear'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-underwear'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-shoes/loafers-oxfords'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-shoes/heels'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-shoes/boots'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-shoes/mules'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-shoes/flats-slingbacks'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-shoes/sneakers'],
            ['women', 'https://www.everlane.com/api/v2/collections/womens-shoes/sandals'],
            ['men', 'https://www.everlane.com/api/v2/collections/mens-jeans'],
            ['men', 'https://www.everlane.com/api/v2/collections/mens-tees'],
            ['men', 'https://www.everlane.com/api/v2/collections/mens-shirt-shop'],
            ['men', 'https://www.everlane.com/api/v2/collections/mens-sweaters'],
            ['men', 'https://www.everlane.com/api/v2/collections/mens-sweatshirts'],
            ['men', 'https://www.everlane.com/api/v2/collections/mens-bottoms'],
            ['men', 'https://www.everlane.com/api/v2/collections/mens-outerwear'],
            ['men', 'https://www.everlane.com/api/v2/collections/mens-underwear'],
            ['men', 'https://www.everlane.com/api/v2/collections/mens-backpacks-bags'],
        ]

    def start_requests(self):
        for _, url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page, headers={'content-type': 'application/json', 'charset': 'UTF-8'})

    def parse_category_page(self, response):
        data = json.loads(response.body_as_unicode())
        # for g in data['groupings']['product_group']:
        #     for pid in g['products']:
        #         self._product_groups[pid] = g['id']
        for p in data['products']:
            yield self.parse_product(p, response)

    def parse_product(self, data, response):
        # product_group = self._product_groups.get(data['id'])
        # if product_group and product_group in self._existing_groups:
        #     return

        p = Product()
        p['gender'] = self.get_gender(data)
        p['description'] = self.get_description(data)
        p['image_url'] = self.get_image_urls(data)
        p['name'] = data['display_name']
        p['brand'] = self.name
        p['url'] = 'https://www.everlane.com/products/' + data['permalink']
        p['price'] = data['price']
        p['original_price'] = data['original_price'] if p['price'] != data['original_price'] else None
        p['currency'] = 'USD'

        # self._existing_groups.add(product_group)

        return p

    def get_image_urls(self, data):
        sq = data['albums']['square']
        if type(sq[0]) == dict:
            return [v['src'] for v in sq]
        return list(set(sq))

    def get_description(self, data):
        if 'details' not in data:
            return
        return BeautifulSoup(data['details'].get('description', ''), 'lxml').text

    def get_gender(self, data):
        if data['gender'] == 'female':
            return 'women'
        elif data['gender'] == 'male':
            return 'men'
        elif data['gender'] == 'unisex':
            return ['women', 'men']
        return
