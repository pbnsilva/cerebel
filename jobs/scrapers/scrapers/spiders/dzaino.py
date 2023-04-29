from scrapy import Spider, Request
from urllib.parse import urljoin
from scrapers.items import Product
from bs4 import BeautifulSoup


class DzainoSpider(Spider):
    name = 'Dzaino'
    allowed_domains = ['dzaino.com']
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(DzainoSpider, self).__init__(*a, **kw)
        self._base_url = 'http://dzaino.com'
        self.urls = [
            {'value': 'http://dzaino.com/produkt-kategorie/essential-oil-bags/', 'gender': ['men', 'women']},
            {'value': 'http://dzaino.com/produkt-kategorie/yoga-bags/', 'gender': ['men', 'women']},
            {'value': 'http://dzaino.com/produkt-kategorie/backpacks/', 'gender': ['men', 'women']},
            {'value': 'http://dzaino.com/produkt-kategorie/travel-bags/', 'gender': ['men', 'women']},
            {'value': 'http://dzaino.com/produkt-kategorie/daily-bags/', 'gender': ['men', 'women']},
            {'value': 'http://dzaino.com/produkt-kategorie/accessories/', 'gender': ['men', 'women']},
        ]
        self._stores = [
            {'name': 'Dzaino Studio', 'address': 'Nansenstraße 17', 'postal_code': '12047', 'city': 'Berlin', 'country': 'Germany', 'location': {'lat': 52.490946, 'lon': 40.7185721}},
        ]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//a[contains(@class, "woocommerce-LoopProduct-link")]/@href').extract()
        for url in urls:
            yield Request(urljoin(self._base_url, url), callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        if 'voucher' in p['name'].lower():
            return

        p['url'] = response.url
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['currency'] = self.get_currency(response)
        p['brand'] = response.meta['brand']
        p['gender'] = response.meta['gender']
        p['stores'] = self._stores
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[contains(@class, "woocommerce-product-gallery__image")]//img/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[contains(@class, "woocommerce-product-details__short-description")]').extract_first()
        return BeautifulSoup(description.replace('<br />', '\n'), 'lxml').text.strip()

    def get_price(self, response):
        price = response.xpath('////span[@class="woocommerce-Price-amount amount"]/text()').extract()[1]
        if not price:
            return
        price = price.replace(',', '.')
        return float(price)

    def get_original_price(self, response):
        price = response.xpath('//del/span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        if not price:
            return
        price = price.replace(',', '.')
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//span[@class="woocommerce-Price-currencySymbol"]/text()').extract_first()
        if currency:
            currency = self.currency_symbol_map.get(currency)
        return currency
