import scrapy
import json
from scrapers.items import Product


class AsketSpider(scrapy.Spider):
    name = "Asket"
    allowed_domains = ["www.asket.com"]

    def __init__(self, *a, **kw):
        super(AsketSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.asket.com/shop/"
        self.urls = [
            {"value": "https://assets.asket.com/api/products_asket/", "gender": ["men"]}
        ]

    def start_requests(self):
        url = self.urls[0]
        yield scrapy.Request(url['value'], callback=self.parse_category_page, meta={'gender': url['gender']})

    def parse_category_page(self, response):
        data = json.loads(response.body.decode('utf-8'))
        for product in data:
            yield self.parse_product(product, response.meta['gender'])

    def parse_product(self, data, gender):
        p = Product()
        p['name'] = data['name']
        p['url'] = self.base_url + data['slug']
        p['description'] = data['ogDescription']
        p['image_url'] = [data['ogImage']]
        p['price'] = data['price']['EUR']
        p['currency'] = 'EUR'
        p['brand'] = self.name
        p['gender'] = gender
        return p
