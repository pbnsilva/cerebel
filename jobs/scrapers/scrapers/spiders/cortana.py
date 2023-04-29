import scrapy
from scrapers.items import Product
from bs4 import BeautifulSoup


# Woocommerce
class CortanaSpider(scrapy.Spider):
    name = "Cortana"
    allowed_domains = ["www.cortana.es"]
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(CortanaSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.cortana.es"
        self._max_pages = 5
        self._category_urls = [
            'https://www.cortana.es/en/shop-online/sales/',
            'https://www.cortana.es/en/shop-online/women-dresses/',
            'https://www.cortana.es/en/shop-online/womens-tops/',
            'https://www.cortana.es/en/shop-online/womens-skirts/',
            'https://www.cortana.es/en/shop-online/womens-pants/',
            'https://www.cortana.es/en/shop-online/jackets/',
            'https://www.cortana.es/en/shop-online/jumpsuit/',
            'https://www.cortana.es/en/shop-online/tulle/',
            'https://www.cortana.es/en/shop-online/accesories/',
        ]

    def start_requests(self):
        for url in self._category_urls:
            for p in range(1, self._max_pages + 1):
                yield scrapy.Request(url + 'page/' + str(p) + '/', callback=self.parse_category_page)

    def parse_category_page(self, response):
        product_urls = response.xpath('//a[contains(@class, "woocommerce-loop-product__link")]/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page)

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['brand'] = self.name
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['url'] = response.url
        p['gender'] = 'women'
        p['currency'] = self.get_currency(response)
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        if '|' in name:
            name = name.split('|')[0]
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//img[@class="slide-image"]/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@itemprop="description"]').extract()
        return BeautifulSoup(description[0], 'lxml').text

    def get_price(self, response):
        price = response.xpath('//p[@class="price"]//ins/span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        if not price:
            price = response.xpath('////span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
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
