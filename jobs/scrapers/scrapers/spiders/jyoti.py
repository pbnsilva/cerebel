from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup


class JyotiSpider(Spider):
    name = 'Jyoti'
    allowed_domains = ['jyoti-fairworks.org']

    def __init__(self, *a, **kw):
        super(JyotiSpider, self).__init__(*a, **kw)
        self.urls = [
            {"value": "https://jyoti-fairworks.org/en/product-category/women/", "gender": ["women"]},
            {"value": "https://jyoti-fairworks.org/en/product-category/men/", "gender": ["men"]},
            {'value': 'https://jyoti-fairworks.org/en/product-category/accessories/', 'gender': ['men', 'women']},
        ]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//a[@class="woocommerce-LoopProduct-link woocommerce-loop-product__link"]/@href').extract()
        for url in urls:
            yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender']})

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
        name = response.xpath('//h1[@class="product_title entry-title"]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="woocommerce-product-gallery__image"]/a/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@itemprop="description"]//div[contains(@class, "su-spoiler-content")]').extract()
        return BeautifulSoup(description[0], 'lxml').text

    def get_price(self, response):
        price = response.xpath('//meta[@itemprop="price"]/@content').extract_first()
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//meta[@itemprop="priceCurrency"]/@content').extract_first()
        return currency
