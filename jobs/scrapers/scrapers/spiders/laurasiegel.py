import scrapy
from scrapers.items import Product
from bs4 import BeautifulSoup


class LauraSiegelSpider(scrapy.Spider):
    name = "Laura Siegel"
    allowed_domains = ["laurasiegelcollection.com"]

    def __init__(self, *a, **kw):
        super(LauraSiegelSpider, self).__init__(*a, **kw)
        self.base_url = "http://laurasiegelcollection.com"
        self._category_urls = [
            'http://laurasiegelcollection.com/product-category/coat/',
            'http://laurasiegelcollection.com/product-category/dress/',
            'http://laurasiegelcollection.com/product-category/jumpsuits/',
            'http://laurasiegelcollection.com/product-category/pant/',
            'http://laurasiegelcollection.com/product-category/skirt/',
            'http://laurasiegelcollection.com/product-category/top/',
        ]

    def start_requests(self):
        for url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page)

    def parse_category_page(self, response):
        product_urls = response.xpath('//div[contains(@class, "shop_item")]/a/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page)

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['brand'] = self.name
        p['url'] = response.url
        p['gender'] = 'women'
        p['currency'] = 'USD'
        yield p

    def get_name(self, response):
        name = response.xpath('//header[@class="desktop"]/h1/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[@id="img_track"]//img/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="readmore"]').extract_first()
        if not description:
            return
        return BeautifulSoup(description, 'lxml').text

    def get_price(self, response):
        price_text = response.xpath('//header[@class="desktop"]/ins/text()').extract_first()
        if price_text:
            return float(price_text.split()[0][1:])

        header = response.xpath('//header[@class="desktop"]').extract_first()
        price_text = header.split('USD')[0].strip().split('</h1>')[1].strip()[1:]
        if price_text:
            return float(price_text)

    def get_original_price(self, response):
        price_text = response.xpath('//header[@class="desktop"]/del/text()').extract_first()
        if price_text:
            return float(price_text.split()[0][1:])
