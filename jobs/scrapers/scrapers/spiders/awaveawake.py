from scrapy import Spider, Request
from urllib.parse import urljoin
from scrapers.items import Product


class AwaveawakeSpider(Spider):
    name = 'AWAVEAWAKE'
    allowed_domains = ['www.awaveawake.com']

    def __init__(self, *a, **kw):
        super(AwaveawakeSpider, self).__init__(*a, **kw)
        self._base_url = 'https://www.awaveawake.com'
        self.urls = [
            {"value": "https://www.awaveawake.com/shop/", "gender": ["women"]},
        ]
        self.label_finder_urls = []

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender'], 'label_finder_urls': self.label_finder_urls})

    def parse_store(self, response):
        urls = response.xpath('//a[@class="ProductList-item-link"]/@href').extract()
        for url in urls:
            yield Request(urljoin(self._base_url, url), callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender'], 'label_finder_urls': response.meta['label_finder_urls']})

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
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[contains(@class, "ProductItem-gallery-slides-item")]//img/@data-src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//meta[@name="description"]/@content').extract_first()
        return description

    def get_price(self, response):
        price = response.xpath('//meta[@property="product:price:amount"]/@content').extract_first()
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//meta[@property="product:price:currency"]/@content').extract_first()
        return currency
