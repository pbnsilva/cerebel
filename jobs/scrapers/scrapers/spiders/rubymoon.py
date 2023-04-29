import scrapy
from scrapers.items import Product
from bs4 import BeautifulSoup


class RubyMoonSpider(scrapy.Spider):
    name = "RubyMoon"
    allowed_domains = ["rubymoon.org.uk"]
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(RubyMoonSpider, self).__init__(*a, **kw)
        self.base_url = "https://rubymoon.org.uk"
        self.urls = [
            {"value": "https://rubymoon.org.uk/shop/", "gender": ["women"]},
        ]

    def start_requests(self):
        for url in self.urls:
            yield scrapy.Request(url['value'], callback=self.parse_category_page, meta={'gender': url['gender']})

    def parse_category_page(self, response):
        product_urls = response.xpath('//a[contains(@class, "woocommerce-LoopProduct-link")]/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page, meta={'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['brand'] = self.name
        p['url'] = response.url
        p['gender'] = response.meta['gender']
        p['price'] = self.get_price(response)
        p['currency'] = self.get_currency(response)
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name.split('-')[0]

    def get_image_urls(self, response):
        urls = response.xpath('//div[contains(@class, "woocommerce-product-gallery")]/figure/div/a/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@id="tab-description"]//p').extract()
        return BeautifulSoup(description[0], 'lxml').text

    def get_price(self, response):
        price = response.xpath('//p[@class!="cart-prod-subtotal"]//span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        price = price.replace(',', '.')
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//span[@class="woocommerce-Price-currencySymbol"]/text()').extract_first()
        currency = self.currency_symbol_map.get(currency)
        return currency
