from scrapy import Spider, Request
from urllib.parse import urljoin
from scrapers.items import Product
from bs4 import BeautifulSoup


class OrganicsocksofswedenSpider(Spider):
    name = 'Organic Socks of Sweden'
    allowed_domains = ['www.organic-socks.com']

    def __init__(self, *a, **kw):
        super(OrganicsocksofswedenSpider, self).__init__(*a, **kw)
        self._base_url = 'http://www.organic-socks.com'
        self.urls = [{"value": "http://www.organic-socks.com/products/sports", "gender": ["men", "women"]}]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//li[@class="ProductCell"]/a/@href').extract()
        for url in urls:
            yield Request(urljoin(self._base_url, url), callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['url'] = response.url
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['currency'] = self.get_currency(response)
        p['brand'] = response.meta['brand']
        p['gender'] = response.meta['gender']
        p['tags'] = ['socks']
        yield p

    def get_name(self, response):
        name = response.xpath('//h2[@class="Product__title"]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//meta[@property="og:image"]/@content').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="Product__description"]').extract_first()
        return BeautifulSoup(description, 'lxml').text.strip()

    def get_price(self, response):
        price = response.xpath('//span[contains(@class, "price_tag")]/text()').extract_first()
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//span[contains(@class, "currency")]/text()').extract_first()
        return currency
