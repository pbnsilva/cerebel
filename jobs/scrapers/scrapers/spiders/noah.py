from scrapy import Spider, Request
from scrapers.items import Product


class NoahSpider(Spider):
    name = 'Noah'
    allowed_domains = ['www.noah-shop.com']

    def __init__(self, *a, **kw):
        super(NoahSpider, self).__init__(*a, **kw)
        self.urls = [
            {"value": "https://www.noah-shop.com/en/vegan-mens-shoes/", "gender": ["men"]},
            {"value": "https://www.noah-shop.com/en/vegan-womens-shoes/", "gender": ["women"]},
        ]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//a[contains(@class, "article")]/@href').extract()
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
        return name.split('|')[0].strip()

    def get_image_urls(self, response):
        urls = response.xpath('//a[@class="media-image"]/@data-image').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//meta[@name="description"]/@content').extract_first()
        return description

    def get_price(self, response):
        price = response.xpath('//meta[@property="product:price:amount"]/@content').extract_first()
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//meta[@property="product:price:currency"]/@content').extract_first()
        return currency
