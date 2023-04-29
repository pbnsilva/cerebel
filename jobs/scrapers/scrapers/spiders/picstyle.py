from scrapy import Spider, Request
from scrapers.items import Product
from scrapy.selector import Selector


class PicstyleSpider(Spider):
    name = 'P.i.C Style'
    allowed_domains = ['pic-style.com']

    def __init__(self, *a, **kw):
        super(PicstyleSpider, self).__init__(*a, **kw)
        self.urls = [
            {"value": "https://pic-style.com/product-category/clothing/jumpsuits/", "gender": ["women"]},
            {"value": "https://pic-style.com/product-category/clothing/tops/", "gender": ["women"]},
            {"value": "https://pic-style.com/product-category/clothing/dresses", "gender": ["women"]},
            {"value": "https://pic-style.com/product-category/clothing/bottoms", "gender": ["women"]},
            {"value": "https://pic-style.com/product-category/clothing/outerwear", "gender": ["women"]},
            {"value": "https://pic-style.com/product-category/shoes/boots", "gender": ["women"]},
            {"value": "https://pic-style.com/product-category/shoes/brogue", "gender": ["women"]},
            {"value": "https://pic-style.com/product-category/shoes/flats", "gender": ["women"]},
            {"value": "https://pic-style.com/product-category/shoes/trainers/", "gender": ["women"]},
        ]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        infos = response.xpath('//div[@class="item-info"]').extract()
        for info in infos:
            info_x = Selector(text=info)
            brand = info_x.xpath('.//h3/text()').extract_first().strip()
            if brand != 'P.i.C' and brand != '':
                continue
            url = info_x.xpath('.//h3//a/@href').extract_first()
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
        return name.split('|')[0].strip()

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="product-thumbnails"]//a/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//meta[@property="og:description"]/@content').extract_first()
        return description

    def get_price(self, response):
        price = response.xpath('//meta[@itemprop="price"]/@content').extract_first()
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//meta[@itemprop="priceCurrency"]/@content').extract_first()
        return currency
