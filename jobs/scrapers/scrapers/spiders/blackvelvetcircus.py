from scrapy import Spider, Request
from urllib.parse import urljoin
from scrapers.items import Product
from bs4 import BeautifulSoup


class BlackvelvetcircusSpider(Spider):
    name = 'Black Velvet Circus'
    allowed_domains = ['shop.blackvelvetcircus.com']

    def __init__(self, *a, **kw):
        super(BlackvelvetcircusSpider, self).__init__(*a, **kw)
        self._base_url = 'http://shop.blackvelvetcircus.com/epages/es215844.sf/en_GB/'
        self.urls = [
            {"value": "http://shop.blackvelvetcircus.com/epages/es215844.sf/en_GB/?ObjectPath=/Shops/es215844/Categories/Tops&PageSize=30", "gender": ["women"]},
            {"value": "http://shop.blackvelvetcircus.com/epages/es215844.sf/en_GB/?ObjectPath=/Shops/es215844/Categories/Bottoms&PageSize=30", "gender": ["women"]},
            {"value": "http://shop.blackvelvetcircus.com/epages/es215844.sf/en_GB/?ObjectPath=/Shops/es215844/Categories/Jackets&PageSize=30", "gender": ["women"]},
            {"value": "http://shop.blackvelvetcircus.com/epages/es215844.sf/en_GB/?ObjectPath=/Shops/es215844/Categories/Dresses&PageSize=30", "gender": ["women"]},
        ]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//a[@title="Go to product"]/@href').extract()
        for url in urls:
            url = urljoin(self._base_url, url)
            yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['url'] = response.url
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['currency'] = 'EUR'
        p['brand'] = response.meta['brand']
        p['gender'] = response.meta['gender']
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[@itemprop="name"]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//img[@itemprop="image"]/@data-src-l').extract()
        return ['http://shop.blackvelvetcircus.com' + url for url in urls]

    def get_description(self, response):
        description = response.xpath('//div[@itemprop="description"]').extract()
        return BeautifulSoup(description[0], 'lxml').text

    def get_price(self, response):
        price = response.xpath('//span[@itemprop="price"]/@content').extract_first()
        return float(price)

    def get_original_price(self, response):
        price = response.xpath('//span[@class="LineThrough"]/text()').extract_first()
        if not price:
            return
        return float(price.split()[0])
