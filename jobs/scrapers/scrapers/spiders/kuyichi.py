from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup
from urllib.parse import quote_plus


class KuyichiSpider(Spider):
    name = 'Kuyichi'
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(KuyichiSpider, self).__init__(*a, **kw)
        self.urls = [
            {"value": "https://kuyichi.com/view/women/women-jeans/women-jeans-super-skinny/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-jeans/women-jeans-skinny/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-jeans/women-jeans-slim/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-jeans/women-jeans-straight/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-jeans/bootcut/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-jeans/women-jeans-boyfriend/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-collection/women-collection-dresses/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-collection/women-collection-knitwear/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-collection/women-collection-outerwear/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-collection/women-collection-shirts/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-collection/women-collection-sweaters/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-collection/women-collection-t-shirts/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/women/women-accessories/", "gender": ["women"]},
            {"value": "https://kuyichi.com/view/men/men-jeans/men-jeans-skinny/", "gender": ["men"]},
            {"value": "https://kuyichi.com/view/men/men-jeans/men-jeans-slim/", "gender": ["men"]},
            {"value": "https://kuyichi.com/view/men/men-jeans/men-jeans-tapered/", "gender": ["men"]},
            {"value": "https://kuyichi.com/view/men/men-jeans/men-jeans-straight/", "gender": ["men"]},
            {"value": "https://kuyichi.com/view/men/men-jeans/men-jeans-regular/", "gender": ["men"]},
            {"value": "https://kuyichi.com/view/men/men-collection/men-collection-outerwear/", "gender": ["men"]},
            {"value": "https://kuyichi.com/view/men/men-collection/men-collection-shirts/", "gender": ["men"]},
            {"value": "https://kuyichi.com/view/men/men-collection/men-collection-sweaters/", "gender": ["men"]},
            {"value": "https://kuyichi.com/view/men/men-collection/men-collection-t-shirts/", "gender": ["men"]},
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
        p['url'] = 'https://clickwire.io/c?s=11&p=11&t=' + quote_plus(response.url)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['currency'] = self.get_currency(response)
        p['brand'] = response.meta['brand']
        p['gender'] = response.meta['gender']
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[contains(@class, "product-title")]/text()').extract_first()
        return name.strip()

    def get_image_urls(self, response):
        urls = response.xpath('//div[contains(@class, "woocommerce-product-gallery__image")]/a/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="product-short-description"]').extract_first()
        return BeautifulSoup(description, 'lxml').text.strip()

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
