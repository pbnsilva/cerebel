import scrapy
from bs4 import BeautifulSoup
import re
from scrapers.items import Product


class MedwindsSpider(scrapy.Spider):
    name = "Med Winds"
    allowed_domains = ["medwinds.com"]

    def __init__(self, *a, **kw):
        super(MedwindsSpider, self).__init__(*a, **kw)
        self.max_pages = 30
        self._category_urls = [
            ['women', 'http://www.medwinds.com/euren/women/dresses'],
            ['women', 'http://www.medwinds.com/euren/women/blouses'],
            ['women', 'http://www.medwinds.com/euren/women/t-shirts'],
            ['women', 'http://www.medwinds.com/euren/women/jackets'],
            ['women', 'http://www.medwinds.com/euren/women/punto'],
            ['women', 'http://www.medwinds.com/euren/women/faldas'],
            ['women', 'http://www.medwinds.com/euren/women/pantalones'],
            ['women', 'http://www.medwinds.com/euren/women/accessories'],
            ['women', 'http://www.medwinds.com/euren/women/shoes'],
            ['men', 'http://www.medwinds.com/euren/men/shirts'],
            ['men', 'http://www.medwinds.com/euren/men/t-shirts'],
            ['men', 'http://www.medwinds.com/euren/men/jackets'],
            ['men', 'http://www.medwinds.com/euren/men/punto'],
            ['men', 'http://www.medwinds.com/euren/men/trousers'],
            ['men', 'http://www.medwinds.com/euren/men/shoes'],
            ['men', 'http://www.medwinds.com/euren/men/accesorios'],
        ]
        self._stores = [
            {'name': 'Med Winds', 'address': 'Weinmeisterstraße 1', 'postal_code': '10178', 'city': 'Berlin', 'country': 'Germany', 'location': {'lat': 52.525792, 'lon': 13.404031}},
        ]

    def start_requests(self):
        for gender, url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page, meta={'gender': gender, 'dont_redirect': True, "handle_httpstatus_list": [302]})

    def parse_category_page(self, response):
        product_urls = response.xpath('//h3[@class="product-name"]/a/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page, meta={'gender': response.meta['gender'], 'dont_redirect': True, "handle_httpstatus_list": [302]})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = response.xpath('//div[@class="product-name top-product-detail"]/h2/text()').extract_first()
        p['image_url'] = self.get_image_urls(response)
        p['gender'] = response.meta['gender']
        p['brand'] = self.name
        p['url'] = response.url
        p['description'] = self.get_description(response)
        p['price'] = self.get_price(response)
        p['currency'] = 'EUR'
        p['stores'] = self._stores
        yield p

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="more-views-verticle"]/div[@class="media-list"]/div[@id="more-slides"]/a[@class="thumb-link"]/@data-image').extract()
        return list(set(urls))

    def get_id(self, response):
        return re.findall(r'https://.*?/[a-z0-9-]+-([0-9]+-[0-9]+).html', response.url)[0]

    def get_description(self, response):
        description = response.xpath('//meta[@name="description"]/@content').extract_first()
        text = BeautifulSoup(description, 'lxml').get_text()
        return text

    def get_price(self, response):
        price_text = response.xpath('//span[@class="price"]/text()').extract_first().strip()
        return float(price_text[1:])
