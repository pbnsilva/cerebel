from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup


class LaniusSpider(Spider):
    name = 'Lanius'
    allowed_domains = ['www.lanius.com']

    def __init__(self, *a, **kw):
        super(LaniusSpider, self).__init__(*a, **kw)
        self._max_pages = 10
        self.urls = [
            {'value': 'https://www.lanius.com/en/shop/new/', 'gender': ['women']},
            {'value': 'https://www.lanius.com/en/shop/clothing/coats-jackets/', 'gender': ['women']},
            {'value': 'https://www.lanius.com/en/shop/clothing/dresses/', 'gender': ['women']},
            {'value': 'https://www.lanius.com/en/shop/clothing/skirts/', 'gender': ['women']},
            {'value': 'https://www.lanius.com/en/shop/clothing/shirts/', 'gender': ['women']},
            {'value': 'https://www.lanius.com/en/shop/clothing/knit/', 'gender': ['women']},
            {'value': 'https://www.lanius.com/en/shop/clothing/lingerie/', 'gender': ['women']},
            {'value': 'https://www.lanius.com/en/shop/clothing/trousers/', 'gender': ['women']},
            {'value': 'https://www.lanius.com/en/shop/sale/', 'gender': ['women']},
            {'value': 'https://www.lanius.com/en/shop/shoes/', 'gender': ['women']},
            {'value': 'https://www.lanius.com/en/shop/accessoires/', 'gender': ['women']},
        ]

    def start_requests(self):
        for url in self.urls:
            for i in range(1, self._max_pages + 1):
                yield Request(url['value'] + '?p=' + str(i), callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//a[contains(@class, "product--image")]/@href').extract()
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
        urls = response.xpath('//img[@itemprop="image"]/@srcset').extract()
        return [sp.split(',')[0] for sp in urls]

    def get_description(self, response):
        description = response.xpath('//div[contains(@class, "product--description")]').extract()
        return BeautifulSoup(description[0], 'lxml').text.strip()

    def get_price(self, response):
        price = response.xpath('//meta[@itemprop="price"]/@content').extract_first()
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//meta[@itemprop="priceCurrency"]/@content').extract_first()
        return currency
