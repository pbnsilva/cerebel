from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup


class MaiamiSpider(Spider):
    name = 'Maiami'
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(MaiamiSpider, self).__init__(*a, **kw)
        self.urls = [
            {'value': 'https://maiami.de/category/essentials/', 'gender': ['women']},
            {"value": "https://maiami.de/category/sweater/", "gender": ["women"]},
            {"value": "https://maiami.de/category/cardigans/", "gender": ["women"]},
            {"value": "https://maiami.de/category/coats/", "gender": ["women"]},
            {"value": "https://maiami.de/category/scarfs/", "gender": ["women"]},
            {"value": "https://maiami.de/category/caps/", "gender": ["women"]},
            {'value': 'https://maiami.de/category/sale/', 'gender': ['women']},
        ]
        self.label_finder_urls = ["https://www.thelabelfinder.com/berlin/maiami/shops/DE/6567761/2950159"]

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
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//img[@class="jck-wt-images__image"]/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[contains(@class, "x-accordion-body")]').extract_first()
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
