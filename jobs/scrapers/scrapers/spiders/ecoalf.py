from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup


class EcoalfSpider(Spider):
    name = 'Ecoalf'
    allowed_domains = ['ecoalf.com']
    custom_settings = {
        'AUTOTHROTTLE_ENABLED': True,
        'AUTOTHROTTLE_START_DELAY': 5,
        'AUTOTHROTTLE_MAX_DELAY': 60,
        'AUTOTHROTTLE_TARGET_CONCURRENCY': 1.0,
    }

    def __init__(self, *a, **kw):
        super(EcoalfSpider, self).__init__(*a, **kw)
        self.urls = [
            {'value': 'https://ecoalf.com/en/vests-120', 'gender': ['women']},
            {'value': 'https://ecoalf.com/en/jackets-and-coats-110', 'gender': ['women']},
            {'value': 'https://ecoalf.com/en/women-shirts-130', 'gender': ['women']},
            {'value': 'https://ecoalf.com/en/sweaters-and-jackets-140', 'gender': ['women']},
            {'value': 'https://ecoalf.com/en/pants-150', 'gender': ['women']},
            {'value': 'https://ecoalf.com/en/knitwear-160', 'gender': ['women']},
            {'value': 'https://ecoalf.com/en/felder-felder-170', 'gender': ['women']},
            {'value': 'https://ecoalf.com/en/dresses-185', 'gender': ['women']},
            {'value': 'https://ecoalf.com/en/sneakers-180', 'gender': ['women']},
            {'value': 'https://ecoalf.com/en/flip-flops-190', 'gender': ['women']},
            {'value': 'https://ecoalf.com/en/backpack-195', 'gender': ['women']},
            {'value': 'https://ecoalf.com/en/jackets-and-coats-210', 'gender': ['men']},
            {'value': 'https://ecoalf.com/en/vests-220', 'gender': ['men']},
            {'value': 'https://ecoalf.com/en/shirts-and-t-shirts-230', 'gender': ['men']},
            {'value': 'https://ecoalf.com/en/pants-240', 'gender': ['men']},
            {'value': 'https://ecoalf.com/en/sweaters-250', 'gender': ['men']},
            {'value': 'https://ecoalf.com/en/knitwear-260', 'gender': ['men']},
            {'value': 'https://ecoalf.com/en/sneakers-270', 'gender': ['men']},
            {'value': 'https://ecoalf.com/en/flip-flops-280', 'gender': ['men']},
        ]
        self.label_finder_urls = ["https://www.thelabelfinder.com/berlin/ecoalf/shops/DE/4362514/2950159"]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender'], 'label_finder_urls': self.label_finder_urls})

    def parse_store(self, response):
        urls = response.xpath('//a[contains(@class, "product-thumbnail")]/@href').extract()
        for url in urls:
            yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender'], 'label_finder_urls': response.meta['label_finder_urls']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['url'] = response.url
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['currency'] = self.get_currency(response)
        p['brand'] = response.meta['brand']
        p['gender'] = response.meta['gender']
        p['label_finder_urls'] = response.meta['label_finder_urls']
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[@itemprop="name"]/span/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[contains(@class, "product-images")]//img/@data-image-large-src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[contains(@class, "product-description")]').extract()
        return BeautifulSoup(description[0], 'lxml').text.strip()

    def get_price(self, response):
        price = response.xpath('//meta[@property="product:price:amount"]/@content').extract_first()
        return float(price)

    def get_original_price(self, response):
        price = response.xpath('//del[@class="regular-price"]/text()').extract_first()
        if not price:
            return
        return float(price[1:])

    def get_currency(self, response):
        currency = response.xpath('//meta[@property="product:price:currency"]/@content').extract_first()
        return currency
