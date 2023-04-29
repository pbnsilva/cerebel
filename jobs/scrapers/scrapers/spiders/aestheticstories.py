from scrapy import Spider, Request
from scrapers.items import Product


class AestheticStoriesSpider(Spider):
    name = 'Aesthetic Stories'
    allowed_domains = ["aestheticstories.com"]
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(AestheticStoriesSpider, self).__init__(*a, **kw)
        self._shop_url = 'https://aestheticstories.com/shop/'

    def start_requests(self):
        yield Request(self._shop_url, callback=self.parse_store, meta={'brand': self.name})

    def parse_store(self, response):
        urls = response.xpath('//a[@class="product-title-link"]/@href').extract()
        for url in urls:
            yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['url'] = response.url
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['brand'] = response.meta['brand']
        p['gender'] = 'women'
        p['currency'] = self.get_currency(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[contains(@class, "product_title")]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[contains(@class, "woocommerce-product-gallery__image")]/a/img/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="woocommerce-product-details__short-description"]').extract_first()
        return description.replace('Size Guide', '')

    def get_price(self, response):
        price = response.xpath('////span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        if not price:
            return
        price = price.replace('.', '').replace(',', '.')
        return float(price)

    def get_original_price(self, response):
        price = response.xpath('//p[@class="price"]/ins/span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        if not price:
            return
        price = price.replace('.', '').replace(',', '.')
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//span[@class="woocommerce-Price-currencySymbol"]/text()').extract_first()
        if currency:
            currency = self.currency_symbol_map.get(currency)
        return currency
