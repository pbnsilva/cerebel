import scrapy
from scrapers.items import Product


class SaltpetreSpider(scrapy.Spider):
    name = "Saltpetre"
    allowed_domains = ["www.iamsaltpetre.com"]

    def __init__(self, *a, **kw):
        super(SaltpetreSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.iamsaltpetre.com"
        self._category_urls = [
            'https://www.iamsaltpetre.com/shop-work-wear/',
        ]

    def start_requests(self):
        for url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page)

    def parse_category_page(self, response):
        product_urls = response.xpath('//a[contains(@class, "woocommerce-LoopProduct-link")]/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page)

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['brand'] = self.name
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['url'] = response.url
        p['gender'] = 'women'
        p['currency'] = 'INR'
        yield p

    def get_name(self, response):
        name = response.xpath('//div[@class="singleprod__title"]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//img[@class="attachment-shop_single size-shop_single"]/@src').extract()
        return list(set(urls))

    def get_description(self, response):
        description = response.xpath('//meta[@property="og:description"]/@content').extract_first()
        return description

    def get_color(self, response):
        text = response.url.replace('-', ' ')
        return list(set(text.lower().split()).intersection(self.colors))

    def get_price(self, response):
        price_text = response.xpath('//span[@class="woocommerce-Price-amount amount"]/text()').extract()[1]
        return float(price_text[:-3].replace(',', '').strip())
