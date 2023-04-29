import scrapy
from scrapers.items import Product
from bs4 import BeautifulSoup


class NoaniSpider(scrapy.Spider):
    name = "Noani"
    allowed_domains = ["noanifashion.de"]
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}
    translate_to = 'en'

    def __init__(self, *a, **kw):
        super(NoaniSpider, self).__init__(*a, **kw)
        self._category_urls = [
            {'value': 'https://noanifashion.de/product-category/herren/', 'gender': ['men']},
            {'value': 'https://noanifashion.de/product-category/damen/', 'gender': ['women']},
        ]

    def start_requests(self):
        for url in self._category_urls:
            yield scrapy.Request(url['value'], callback=self.parse_category_page, meta={'gender': url['gender']})

    def parse_category_page(self, response):
        product_urls = response.xpath('//div[contains(@class, "product-media")]/a/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page, meta={'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['brand'] = self.name
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['url'] = response.url
        p['gender'] = response.meta['gender']
        p['currency'] = self.get_currency(response)
        p['tags'] = ['belts']
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[contains(@class, "product_title")]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[contains(@class, "product-image")]/img/@data-flickity-lazyload').extract()
        if not urls:
            urls = response.xpath('//div[contains(@class, "product-image")]/img/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="woocommerce-product-details__short-description"]').extract_first()
        if not description:
            description = response.xpath('//div[contains(@class, "woocommerce-Tabs-panel--description")]/div/p/text()').extract_first()
        return BeautifulSoup(description, 'lxml').text

    def get_price(self, response):
        price = response.xpath('//p[@class="price"]/span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        if not price:
            price = response.xpath('//p[@class="price"]/ins/span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        if not price:
            return
        price = price.replace('.', '').replace(',', '.')
        return float(price)

    def get_original_price(self, response):
        price = response.xpath('//p[@class="price"]/del/span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        if not price:
            return
        price = price.replace('.', '').replace(',', '.')
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//span[@class="woocommerce-Price-currencySymbol"]/text()').extract_first()
        if currency:
            currency = self.currency_symbol_map.get(currency)
        return currency
