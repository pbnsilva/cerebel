from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup


class BirdsongSpider(Spider):
    name = 'Birdsong'
    allowed_domains = ['birdsong.london']

    def __init__(self, *a, **kw):
        super(BirdsongSpider, self).__init__(*a, **kw)
        self._max_pages = 5
        self.urls = [
            {"value": "https://birdsong.london/product-category/clothing/tops/", "gender": ["women"]},
            {"value": "https://birdsong.london/product-category/clothing/knitwear/", "gender": ["women"]},
            {"value": "https://birdsong.london/product-category/clothing/coats/", "gender": ["women"]},
            {"value": "https://birdsong.london/product-category/clothing/dresses/", "gender": ["women"]},
            {"value": "https://birdsong.london/product-category/clothing/skirts-and-shorts/", "gender": ["women"]},
        ]

    def start_requests(self):
        for i in range(1, self._max_pages+1):
            for url in self.urls:
                url_val = url['value'] + 'page/' + str(i)
                yield Request(url_val, callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//a[@class="woocommerce-LoopProduct-link woocommerce-loop-product__link"]/@href').extract()
        for url in urls:
            yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['url'] = response.url
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['currency'] = 'GBP'
        p['brand'] = response.meta['brand']
        p['gender'] = response.meta['gender']
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[@itemprop="name"]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="product-image"]/img/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@itemprop="description"]').extract()
        return BeautifulSoup(description[0], 'lxml').text

    def get_price(self, response):
        price = response.xpath('//p[@class!="cart-prod-subtotal"]//span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
        price = price.replace(',', '.')
        return float(price)
