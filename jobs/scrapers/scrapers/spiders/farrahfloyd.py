import scrapy
from scrapers.items import Product


class FarrahFloydSpider(scrapy.Spider):
    name = "Farrah Floyd"
    allowed_domains = ["www.farrahfloyd.com", "farrahfloyd.com"]

    def __init__(self, *a, **kw):
        super(FarrahFloydSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.farrahfloyd.com"
        self._category_urls = [
            'https://farrahfloyd.com/product-category/tops/',
            'https://farrahfloyd.com/product-category/jacketscoats/',
            'https://farrahfloyd.com/product-category/dressesjumpsuits/',
            'https://farrahfloyd.com/product-category/skirtstrousers/',
        ]

    def start_requests(self):
        for url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page)

    def parse_category_page(self, response):
        product_urls = response.xpath('//ul[@class="products"]/li[contains(@class, "product")]/a[1]/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page)

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['brand'] = self.name
        p['url'] = response.url
        p['gender'] = 'women'
        p['currency'] = 'EUR'
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[@itemprop="name"]/text()').extract_first()
        return name

    def get_description(self, response):
        desc = response.xpath('//div[@id="tab-description"]/p/text()').extract_first()
        return desc

    def get_image_urls(self, response):
        urls = response.xpath('//figure/div/a/@href').extract()
        return urls

    def get_price(self, response):
        price = response.xpath('//script[@type="application/ld+json"]').re_first('price":"(.+?)"')
        if not price:
            return None
        return float(price)
