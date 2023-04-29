import scrapy
import json
from urllib.parse import urljoin
from scrapers.items import Product
from bs4 import BeautifulSoup


class AdaySpider(scrapy.Spider):
    name = "ADAY"
    allowed_domains = ["www.thisisaday.com"]

    def __init__(self, *a, **kw):
        super(AdaySpider, self).__init__(*a, **kw)
        self.base_url = "https://www.thisisaday.com"
        self.urls = [{"value": "https://www.thisisaday.com/api/products", "gender": ["women"]}]
        self._stores = [
            {'name': 'ADAY', 'address': '264 Canal St', 'postal_code': '10013', 'city': 'New York', 'country': 'United States', 'location': {'lat': 40.7185721, 'lon': -74.0034014}},
        ]

    def start_requests(self):
        yield scrapy.Request(self.urls[0]['value'], callback=self.parse_category_page)

    def parse_category_page(self, response):
        data = json.loads(response.body.decode('utf-8'))
        for product in data["products"]:
            url = urljoin(self.base_url, '/api/products/' + product['slug'])
            yield scrapy.Request(url, callback=self.parse_product_page)

    def parse_product_page(self, response):
        data = json.loads(response.body.decode('utf-8'))

        if data['slug'] in {'gift-card', 'an-act-a-day-postcards'}:
            return

        p = Product()
        p['name'] = self.get_name(data)
        p['url'] = self.get_product_url(data['slug'])
        p['description'] = self.get_description(data)
        p['image_url'] = self.get_image_urls(data)
        p['currency'] = 'usd'
        p['price'] = self.get_price(data)
        p['original_price'] = self.get_original_price(data)
        p['brand'] = self.name
        p['gender'] = 'women'
        p['stores'] = self._stores
        yield p

    def get_name(self, product):
        return product["name"]

    def get_description(self, product):
        return BeautifulSoup(product["story"], 'lxml').get_text() + BeautifulSoup(product["fit"], 'lxml').get_text()

    def get_image_urls(self, product):
        return [img['product_feed_url'] for img in product['master']['images'] if not img['is_slider_image']]

    def get_product_url(self, slug):
        return 'https://www.thisisaday.com/products/' + slug

    def get_price(self, product):
        price = product["price"]
        return float(price)

    def get_original_price(self, product):
        price = product["original_price"]
        if not price:
            return
        return float(price)
