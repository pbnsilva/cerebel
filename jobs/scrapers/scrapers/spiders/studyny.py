import scrapy
from urllib.parse import urljoin
from bs4 import BeautifulSoup
from scrapers.items import Product


class StudyNYSpider(scrapy.Spider):
    name = "Study NY"
    allowed_domains = ["study-ny.com"]

    def __init__(self, *a, **kw):
        super(StudyNYSpider, self).__init__(*a, **kw)
        self.base_url = "http://study-ny.com"
        self._category_urls = [
            'http://study-ny.com/shop/',
        ]

    def start_requests(self):
        for url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page)

    def parse_category_page(self, response):
        product_urls = response.xpath('//a[contains(@class, "product")]/@href').extract()
        for url in product_urls:
            yield scrapy.Request(urljoin(self.base_url, url), callback=self.parse_product_page)

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['currency'] = self.get_currency(response)
        p['brand'] = self.name
        p['url'] = response.url
        p['gender'] = ['women']
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="slide"]/img/@data-src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="product-description"]').extract_first()
        if not description:
            return
        return BeautifulSoup(description, 'lxml').text.strip()

    def get_price(self, response):
        price = response.xpath('//meta[@property="product:price:amount"]/@content').extract_first()
        return float(price)

    def get_original_price(self, response):
        price = response.xpath('//meta[@property="product:original_price:amount"]/@content').extract_first()
        if not price:
            return
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//meta[@property="product:price:currency"]/@content').extract_first()
        return currency
