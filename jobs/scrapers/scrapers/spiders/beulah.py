import scrapy
from urllib.parse import quote_plus
from scrapers.items import Product


# Woocommerce
class BeulahSpider(scrapy.Spider):
    name = "Beulah"
    allowed_domains = ["www.beulahlondon.com"]
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(BeulahSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.beulahlondon.com"
        self._max_pages = 5
        self._category_urls = [
            'https://www.beulahlondon.com/product-category/sale/',
            'https://www.beulahlondon.com/product-category/clothing/dresses/',
            'https://www.beulahlondon.com/product-category/clothing/jumpsuits/',
            'https://www.beulahlondon.com/product-category/clothing/jackets-coats/',
            'https://www.beulahlondon.com/product-category/clothing/tops-blouses/',
            'https://www.beulahlondon.com/product-category/clothing/trousers-skirts/',
            'https://www.beulahlondon.com/product-category/clothing/scarves/',
            'https://www.beulahlondon.com/product-category/clothing/bags/',
            'https://www.beulahlondon.com/product-category/clothing/accessories/',
        ]

    def start_requests(self):
        for url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page)

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
        p['url'] = 'https://click.linksynergy.com/deeplink?id=VTA2/22Mkg4&mid=43863&murl=%s' % quote_plus(response.url)
        p['gender'] = 'women'
        p['currency'] = self.get_currency(response)
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        if '|' in name:
            name = name.split('|')[0]
        return name.strip()

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="slick-slider thumbnails"]/a/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//meta[@name="description"]/@content').extract_first()
        return description

    def get_price(self, response):
        price = response.xpath('////span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
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
