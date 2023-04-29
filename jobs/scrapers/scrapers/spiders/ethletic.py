from scrapy import Spider, Request
from scrapers.items import Product


class EthleticSpider(Spider):
    name = 'Ethletic'
    allowed_domains = ['shop.ethletic.com']
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(EthleticSpider, self).__init__(*a, **kw)
        self.urls = [
            {"value": "https://shop.ethletic.com/en/sneakers/fair-trainer-col-18/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/fair-trainer-classics/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/black-caps-col-18/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/black-cap-classics/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/goto-col-18/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/fair-deck-col-18/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/fair-deck-classic/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/fair-skater-classic/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/randall-col-18/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/root-col-18/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/hiro-col-18/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/fair-dancer-col-18/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/sneakers/fair-dancer-classic/", "gender": ["men", "women"]},
            {"value": "https://shop.ethletic.com/en/more/kung-fu-shoes/", "gender": ["men", "women"]},
        ]
        self.label_finder_urls = ["https://www.thelabelfinder.com/berlin/ethletic/shops/DE/1485876/2950159"]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender'], 'label_finder_urls': self.label_finder_urls})

    def parse_store(self, response):
        urls = response.xpath('//a[@class="product-link"]/@href').extract()
        for url in urls:
            yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender'], 'label_finder_urls': response.meta['label_finder_urls']})

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
        p['label_finder_urls'] = response.meta['label_finder_urls']
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="images"]/img/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//meta[@property="og:description"]/@content').extract_first()
        return description

    def get_price(self, response):
        price = response.xpath('//span[@class="price"]/text()').extract_first()
        price = price.replace(',', '.').strip()[1:]
        return float(price)

    def get_currency(self, response):
        price = response.xpath('//span[@class="price"]/text()').extract_first()
        currency = self.currency_symbol_map.get(price.strip()[0])
        return currency
