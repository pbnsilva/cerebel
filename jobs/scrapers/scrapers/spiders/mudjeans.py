import re
from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup


class MudjeansSpider(Spider):
    name = 'MudJeans'
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(MudjeansSpider, self).__init__(*a, **kw)
        self._pagination_pattern = re.compile('^https?:.*[\\?&]page=\\d{1}$')
        self.urls = [
            {"value": "https://mudjeans.eu/shop/women-buy-jeans/", "gender": ["women"]},
            {"value": "https://mudjeans.eu/shop/women-buy-tops-tylerjacket/", "gender": ["women"]},
            {"value": "https://mudjeans.eu/shop/women-buy-tops-eddie/", "gender": ["women"]},
            {"value": "https://mudjeans.eu/shop/women-buy-tops-t-shirts/", "gender": ["women"]},
            {"value": "https://mudjeans.eu/shop/women-buy-others-totobag/", "gender": ["women"]},
            {"value": "https://mudjeans.eu/shop/men-jeans/", "gender": ["men"]},
            {"value": "https://mudjeans.eu/shop/men-buy-tops-george/", "gender": ["men"]},
            {"value": "https://mudjeans.eu/shop/men-buy-tops-tylerjacket/", "gender": ["men"]},
            {"value": "https://mudjeans.eu/shop/men-buy-tops-eddie/", "gender": ["men"]},
            {"value": "https://mudjeans.eu/shop/men-buy-tops-t-shirts/", "gender": ["men"]},
            {"value": "https://mudjeans.eu/shop/men-buy-others-totobag/", "gender": ["men"]},
        ]
        self.label_finder_urls = ['https://www.thelabelfinder.com/berlin/mud-jeans%C2%AE/shops/DE/4265805/2950159']

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender'], 'label_finder_urls': self.label_finder_urls})

    def parse_store(self, response):
        urls = response.xpath('//a[contains(@class, "woocommerce-LoopProduct-link")]/@href').extract()
        for url in urls:
            yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender'], 'label_finder_urls': response.meta['label_finder_urls']})

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
        p['label_finder_urls'] = response.meta['label_finder_urls']
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[contains(@class, "product_title")]/text()').extract_first()
        return name.strip()

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="woocommerce-product-gallery__image"]/a/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@id="details"]').extract()
        return BeautifulSoup(description[0], 'lxml').text.strip()

    def get_price(self, response):
        price = response.xpath('//p[contains(@class, "price")]/ins/span[contains(@class, "amount")]/text()').extract_first()
        if not price:
            price = response.xpath('//p[contains(@class, "price")]/span[contains(@class, "amount")]/text()').extract_first()
        if not price:
            price = response.xpath('//span[contains(@class, "woocommerce-Price-amount")]/text()').extract_first()
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
        currency = self.currency_symbol_map.get(currency)
        return currency
