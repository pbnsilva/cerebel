from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup


class JannjuneSpider(Spider):
    name = 'JannJune'
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(JannjuneSpider, self).__init__(*a, **kw)
        self.urls = [
            {'value': 'https://jannjune.com/produkt-kategorie/womenswear/tops-womenswear/', 'gender': ['women']},
            {'value': 'https://jannjune.com/produkt-kategorie/womenswear/sweaters-cardigans-womenswear/', 'gender': ['women']},
            {'value': 'https://jannjune.com/produkt-kategorie/womenswear/dressesjumpsuits-womenswear/', 'gender': ['women']},
            {'value': 'https://jannjune.com/produkt-kategorie/womenswear/blouses-womenswear/', 'gender': ['women']},
            {'value': 'https://jannjune.com/produkt-kategorie/womenswear/bottoms-womenswear/', 'gender': ['women']},
            {'value': 'https://jannjune.com/produkt-kategorie/womenswear/blazer-coats-womenswear/', 'gender': ['women']},
            {'value': 'https://jannjune.com/produkt-kategorie/womenswear/accessories-womenswear/', 'gender': ['women']},
            {'value': 'https://jannjune.com/produkt-kategorie/sale/', 'gender': ['women']},
            {'value': 'https://jannjune.com/produkt-kategorie/menswear/tops-menswear/', 'gender': ['men']},
            {'value': 'https://jannjune.com/produkt-kategorie/menswear/bottoms-menswear/', 'gender': ['men']},
            {'value': 'https://jannjune.com/produkt-kategorie/menswear/accessories-menswear/', 'gender': ['men']},
        ]
        self.label_finder_urls = []

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender'], 'label_finder_urls': self.label_finder_urls})

    def parse_store(self, response):
        urls = response.xpath('//a[contains(@class, "product-title-link")]/@href').extract()
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
        if response.meta['label_finder_urls']:
            p['label_finder_urls'] = response.meta['label_finder_urls']
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[contains(@class, "product_title")]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[contains(@class, "product-image")]//img/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="woocommerce-product-details__short-description"]').extract_first()
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
