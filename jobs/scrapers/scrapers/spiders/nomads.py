from scrapy import Spider, Request
from scrapers.items import Product
from urllib.parse import urljoin


class NomadsSpider(Spider):
    name = 'Nomads'
    allowed_domains = ['www.nomadsclothing.com']
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(NomadsSpider, self).__init__(*a, **kw)
        self._base_url = 'https://www.nomadsclothing.com'
        self.urls = [
            {"value": "https://www.nomadsclothing.com/clothing/tunics", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/womenswear/dresses", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/womenswear/tops", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/womenswear/knitwear", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/womenswear/plain-basics", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/womenswear/coats", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/womenswear/trousers", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/womenswear/skirts", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/womenswear/cardigans", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/womenswear/scarves", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/womenswear/footwear", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/organic/dresses", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/organic/trousers-skirts", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/organic/tops-tunics", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/MensShirts", "gender": ["men"]},
            {"value": "https://www.nomadsclothing.com/accessories/scarves-sarongs", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/accessories/bags", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/accessories/tights", "gender": ["women"]},
            {"value": "https://www.nomadsclothing.com/womenswear/footwear", "gender": ["women"]},
        ]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//div[contains(@class, "item")]/a/@href').extract()
        for url in urls:
            yield Request(urljoin(self._base_url, url), callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['url'] = response.url.split('?')[0]
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['currency'] = self.get_currency(response)
        p['brand'] = response.meta['brand']
        p['gender'] = response.meta['gender']
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//ul[@class="bxslider"]//img/@src').extract()
        return [urljoin(self._base_url, u) for u in urls]

    def get_description(self, response):
        description = response.xpath('//meta[@property="og:description"]/@content').extract_first()
        return description

    def get_original_price(self, response):
        price = response.xpath('//span[@class="reduced"]/text()').extract_first()
        return float(price.strip()[1:])

    def get_price(self, response):
        price = response.xpath('//span[@itemprop="price"]/text()').extract_first()
        if not price:
            price = response.xpath('//span[@class="price"]/text()').extract_first()
        return float(price.strip()[1:])

    def get_currency(self, response):
        price = response.xpath('//span[@class="price"]/text()').extract_first()
        return self.currency_symbol_map[price.strip()[0]]
