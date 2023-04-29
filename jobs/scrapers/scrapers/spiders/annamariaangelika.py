import scrapy
from urllib.parse import urljoin
from scrapers.items import Product
from bs4 import BeautifulSoup


class AnnaMariaAngelikaSpider(scrapy.Spider):
    name = "ANNAMARIAANGELIKA"
    trim_border = True
    allowed_domains = ["www.annamariaangelika.com"]
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(AnnaMariaAngelikaSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.annamariaangelika.com"
        self._max_pages = 5
        self.urls = [
            {"value": "https://www.annamariaangelika.com/product-category/for-women/", "gender": ["women"]},
            {"value": "https://www.annamariaangelika.com/product-category/for-men/", "gender": ["men"]},
        ]

    def start_requests(self):
        for url in self.urls:
            for i in range(1, self._max_pages+1):
                yield scrapy.Request(urljoin(url['value'], "page/%d/" % i), callback=self.parse_category_page, meta={'gender': url['gender']})

    def parse_category_page(self, response):
        urls = response.xpath('//a[contains(@class, "woocommerce-loop-product__link")]/@href').extract()
        for url in urls:
            yield scrapy.Request(url, callback=self.parse_product_page, meta={'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)

        if 'gift card' in p['name'].lower():
            return

        p['url'] = response.url
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['currency'] = self.get_currency(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['brand'] = self.name
        p['gender'] = response.meta['gender']
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[contains(@class, "product_title")]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="woocommerce-product-gallery__image"]/a/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="accordion_content_inner"]').extract_first()
        if not description:
            return
        return BeautifulSoup(description, 'lxml').text.strip()

    def get_price(self, response):
        price = response.xpath('////span[@class="woocommerce-Price-amount amount"]/text()').extract()
        if len(price) > 1:
            price = price[1]
        else:
            price = price[0]
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
