from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup


class DressarteSpider(Spider):
    name = 'Dressarte'
    allowed_domains = ['www.dressarteparis.com']
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR', 'EUR': 'EUR'}

    def __init__(self, *a, **kw):
        super(DressarteSpider, self).__init__(*a, **kw)
        self.urls = [
            {'value': 'https://www.dressarteparis.com/product-category/last-chance/', 'gender': ['women']},
            {"value": "https://www.dressarteparis.com/product-category/tops/", "gender": ["women"]},
            {"value": "https://www.dressarteparis.com/product-category/bottoms/", "gender": ["women"]},
            {"value": "https://www.dressarteparis.com/product-category/dresses/", "gender": ["women"]},
            {"value": "https://www.dressarteparis.com/product-category/outwear/", "gender": ["women"]},
        ]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//p[contains(@class, "product-title")]/a/@href').extract()
        for url in urls:
            yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['url'] = response.url
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['currency'] = self.get_currency(response)
        p['brand'] = response.meta['brand']
        p['gender'] = response.meta['gender']
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[contains(@class, product-title)]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[contains(@class, "woocommerce-product-gallery__image")]/a/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="product-short-description"]').extract_first()
        return BeautifulSoup(description, 'lxml').text.strip()

    def get_price(self, response):
        price = response.xpath('//p[contains(@class, "price")]/ins/span[contains(@class, "amount")]/text()').extract_first()
        if not price:
            price = response.xpath('//p[contains(@class, "price")]/span[@class="amount"]/text()').extract_first()
            price = price[1:]
        if not price:
            return
        return float(price.replace(',', '.'))

    def get_original_price(self, response):
        price = response.xpath('//p[contains(@class, "price")]/del/span[contains(@class, "amount")]/text()').extract_first()
        if not price:
            return
        return float(price.replace(',', '.'))

    def get_currency(self, response):
        currency = response.xpath('//span[@class="woocommerce-Price-currencySymbol"]/text()').extract_first()
        if currency:
            currency = self.currency_symbol_map.get(currency)
        return currency
