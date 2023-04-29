import scrapy
from urllib.parse import urljoin
from scrapers.items import Product
from bs4 import BeautifulSoup


class NataschaVonHirschhausenSpider(scrapy.Spider):
    name = "Natascha von Hirschhausen"
    allowed_domains = ["www.nataschavonhirschhausen.com"]
    translate_to = 'en'

    def __init__(self, *a, **kw):
        super(NataschaVonHirschhausenSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.nataschavonhirschhausen.com"
        self._category_urls = [
            'https://www.nataschavonhirschhausen.com/onlineshop/jacken-m%C3%A4ntel-capes/',
            'https://www.nataschavonhirschhausen.com/onlineshop/kleider/',
            'https://www.nataschavonhirschhausen.com/onlineshop/tops-blusen/',
            'https://www.nataschavonhirschhausen.com/onlineshop/hosen-r%C3%B6cke/',
            'https://www.nataschavonhirschhausen.com/onlineshop/fairer-silberschmuck/',
            'https://www.nataschavonhirschhausen.com/onlineshop/strickkollektion/',
        ]

    def start_requests(self):
        for url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page)

    def parse_category_page(self, response):
        product_urls = response.xpath('//a/@href').extract()
        for url in product_urls:
            if not url.startswith('/onlineshop/'):
                continue
            yield scrapy.Request(urljoin(self.base_url, url), callback=self.parse_product_page)

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)[:5]
        p['brand'] = self.name
        p['url'] = response.url
        p['gender'] = 'women'
        p['price'] = self.get_price(response)
        p['currency'] = 'EUR'
        yield p

    def get_name(self, response):
        return response.xpath('//meta[@property="og:title"]/@content').extract_first()

    def get_image_urls(self, response):
        urls = response.xpath('//div[@id="content_area"]//img/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="j-module n j-text "]').extract()
        return BeautifulSoup(description[0], 'lxml').text.strip()

    def get_price(self, response):
        price = response.xpath('//p[@itemprop="price"]/@content').extract_first()
        if not price:
            return
        return float(price.replace(',', ''))
