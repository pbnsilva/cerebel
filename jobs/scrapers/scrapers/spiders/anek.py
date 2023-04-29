from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup


class AnekSpider(Spider):
    name = 'Anek.'
    allowed_domains = ['anekdotboutique.com']

    def __init__(self, *a, **kw):
        super(AnekSpider, self).__init__(*a, **kw)
        self.urls = [
            {"value": "https://anekdotboutique.com/product-category/sets/", "gender": ["women"]},
            {"value": "https://anekdotboutique.com/product-category/panties/", "gender": ["women"]},
            {"value": "https://anekdotboutique.com/product-category/bras/", "gender": ["women"]},
            {"value": "https://anekdotboutique.com/product-category/lounge", "gender": ["women"]},
            {"value": "https://anekdotboutique.com/product-category/swim", "gender": ["women"]},
            {"value": "https://anekdotboutique.com/product-category/swim", "gender": ["women"]},
            {"value": "https://anekdotboutique.com/product-category/accessories/", "gender": ["women"]},
        ]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//a[@class="product-images"]/@href').extract()
        for url in urls:
            yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['url'] = response.url
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['currency'] = self.get_currency(response)
        p['brand'] = response.meta['brand']
        p['gender'] = response.meta['gender']
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//a[@itemprop="image"]/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@itemprop="description"]//div[contains(@class, "tab-pane")]/text()').extract()
        return BeautifulSoup(description[0], 'lxml').text

    def get_price(self, response):
        price = response.xpath('//meta[@itemprop="price"]/@content').extract_first()
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//meta[@itemprop="priceCurrency"]/@content').extract_first()
        return currency
