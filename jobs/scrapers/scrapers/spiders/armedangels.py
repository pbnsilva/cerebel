from scrapy import Spider, Request
from urllib.parse import urljoin
from scrapers.items import Product


class ArmedangelsSpider(Spider):
    name = 'ARMEDANGELS'
    allowed_domains = ['www.armedangels.de']
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(ArmedangelsSpider, self).__init__(*a, **kw)
        self.urls = [
            {'value': 'https://www.armedangels.de/en/women-sale', 'gender': ['women']},
            {'value': 'https://www.armedangels.de/en/men-sale', 'gender': ['men']},
            {"value": "https://www.armedangels.de/en/men-t-shirts-basic", "gender": ["men"]},
            {"value": "https://www.armedangels.de/en/men-t-shirts-print", "gender": ["men"]},
            {"value": "https://www.armedangels.de/en/men-shirts-polos", "gender": ["men"]},
            {"value": "https://www.armedangels.de/en/men-longsleeves", "gender": ["men"]},
            {"value": "https://www.armedangels.de/en/men-sweaters-cardigans", "gender": ["men"]},
            {"value": "https://www.armedangels.de/en/men-sweatshirts-hoodies", "gender": ["men"]},
            {"value": "https://www.armedangels.de/en/men-denim-pants", "gender": ["men"], "tags": ["jeans"]},
            {"value": "https://www.armedangels.de/en/men-jackets-coats", "gender": ["men"]},
            {"value": "https://www.armedangels.de/en/women-dresses-skirts", "gender": ["women"]},
            {"value": "https://www.armedangels.de/en/women-blouses", "gender": ["women"]},
            {"value": "https://www.armedangels.de/en/women-t-shirts-basic", "gender": ["women"]},
            {"value": "https://www.armedangels.de/en/women-t-shirts-print", "gender": ["women"]},
            {"value": "https://www.armedangels.de/en/women-tops", "gender": ["women"]},
            {"value": "https://www.armedangels.de/en/women-longsleeves", "gender": ["women"]},
            {"value": "https://www.armedangels.de/en/women-sweaters-cardigans", "gender": ["women"]},
            {"value": "https://www.armedangels.de/en/women-sweatshirts-hoodies", "gender": ["women"]},
            {"value": "https://www.armedangels.de/en/women-pants", "gender": ["women"]},
            {"value": "https://www.armedangels.de/en/women-denims", "gender": ["women"], "tags": ["jeans"]},
            {"value": "https://www.armedangels.de/en/women-blazers-jackets", "gender": ["women"]},
        ]
        self._base_url = 'https://www.armedangels.de/en/'
        self.label_finder_urls = ["https://www.thelabelfinder.com/berlin/armedangels/shops/DE/374199/2950159"]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender'], 'label_finder_urls': self.label_finder_urls, 'tags': url.get('tags')})

    def parse_store(self, response):
        urls = response.xpath('//a[@class="product-image"]/@href').extract()
        for url in urls:
            yield Request(urljoin(self._base_url, url), callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender'], 'label_finder_urls': response.meta['label_finder_urls'], 'tags': response.meta.get('tags')})

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
        if response.meta['tags']:
            p['tags'] = response.meta['tags']
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//a[@class="fancybox"]/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[contains(@class, "product-name")]//h2/text()').extract_first()
        return description

    def get_price(self, response):
        price = response.xpath('//p[@class="special-price"]//span[@class="price"]/text()').extract_first()
        if not price:
            price = response.xpath('//span[@class="price"]/text()').extract_first()
        return float(price.strip()[1:])

    def get_original_price(self, response):
        price = response.xpath('//p[@class="old-price"]//span[@class="price"]/text()').extract_first()
        if not price:
            return
        return float(price.strip()[1:])

    def get_currency(self, response):
        price = response.xpath('//span[@class="price"]/text()').extract_first().strip()
        currency = self.currency_symbol_map.get(price[0])
        return currency
