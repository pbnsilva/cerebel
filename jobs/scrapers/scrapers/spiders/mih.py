import scrapy
from scrapers.items import Product
from urllib.parse import quote_plus


class MihSpider(scrapy.Spider):
    name = "M.i.h."
    allowed_domains = ["www.mih-jeans.com", "us.mih-jeans.com"]

    def __init__(self, *a, **kw):
        super(MihSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.mih-jeans.com"
        self._category_urls = [
            'https://www.mih-jeans.com/womens-jeans',
            'https://www.mih-jeans.com/womens-shirts',
            'https://www.mih-jeans.com/knits',
            'https://www.mih-jeans.com/tops',
            'https://www.mih-jeans.com/dresses-skirts',
            'https://www.mih-jeans.com/trousers-shorts',
            'https://www.mih-jeans.com/jackets',
            'https://www.mih-jeans.com/all-in-one',
        ]

    def start_requests(self):
        for url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page)

    def parse_category_page(self, response):
        product_urls = response.xpath('//p[@class="product-name"]/a/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page)

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['brand'] = self.name
        p['url'] = self.get_affiliate_link(response.url)
        p['gender'] = 'women'
        p['currency'] = self.get_currency(response)
        yield p

    def get_affiliate_link(self, url):
        return 'https://click.linksynergy.com/deeplink?id=VTA2/22Mkg4&mid=38095&murl=%s' % quote_plus(url)

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//img[@class="unveil"]/@data-src').extract()
        return list(set(urls))

    def get_description(self, response):
        description = response.xpath('//meta[@property="og:description"]/@content').extract_first()
        return description

    def get_price(self, response):
        price = response.xpath('//meta[@property="og:price:amount"]/@content').extract_first()
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//meta[@property="og:price:currency"]/@content').extract_first()
        return currency
