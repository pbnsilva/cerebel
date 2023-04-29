from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup


class OmybagSpider(Spider):
    name = 'O MY BAG'
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(OmybagSpider, self).__init__(*a, **kw)
        self.urls = [
            {"value": "https://www.omybag.nl/product-category/women/women-bags/", "gender": ["women"]},
            {"value": "https://www.omybag.nl/product-tag/travel-women/", "gender": ["women"]},
            {"value": "https://www.omybag.nl/product-category/women/women-accessories/women-wallets/", "gender": ["women"]},
            {"value": "https://www.omybag.nl/product-category/men/men-bags/", "gender": ["men"]},
            {"value": "https://www.omybag.nl/product-tag/travel-men/", "gender": ["men"]},
            {"value": "https://www.omybag.nl/product-category/men/men-accessories/men-wallets/", "gender": ["men"]},
        ]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//a[contains(@class, "woocommerce-LoopProduct-link")]/@href').extract()
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
        name = response.xpath('//h1[@class="title"]/text()').extract_first()
        return name.strip().title()

    def get_image_urls(self, response):
        urls = response.xpath('//a[contains(@class, "yith_magnifier_thumbnail")]/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[contains(@class, "tab-description")]').extract_first()
        return BeautifulSoup(description, 'lxml').text.strip()

    def get_price(self, response):
        price = response.xpath('//p[@class="price"]/span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        if not price:
            price = response.xpath('//p[@class="price"]/ins/span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        if not price:
            return
        return float(price)

    def get_original_price(self, response):
        price = response.xpath('//p[@class="price"]/del/span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        if not price:
            return
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//span[@class="woocommerce-Price-currencySymbol"]/text()').extract_first()
        if currency:
            currency = self.currency_symbol_map.get(currency)
        return currency
