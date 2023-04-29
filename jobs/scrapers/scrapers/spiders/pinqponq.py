import scrapy
from scrapers.items import Product


class PinqponqSpider(scrapy.Spider):
    name = "pinqponq"
    allowed_domains = ["www.pinqponq.com"]
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(PinqponqSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.pinqponq.com"
        self.urls = [
            {'value': 'https://www.pinqponq.com/en/shop/blok/17_4/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/karavan/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/kart/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/cubik/17_4/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/cubik/15_5/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/blok/15_5/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/cubik/14_3/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/klak/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/okay/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/jakk/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/purik/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/brik/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/klick/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/kit/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/dj-cubik/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/took/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/tetrik/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/pak/', 'gender': ['women', 'men']},
            {'value': 'https://www.pinqponq.com/en/shop/kover/', 'gender': ['women', 'men']},
        ]

    def start_requests(self):
        for url in self.urls:
            yield scrapy.Request(url['value'], callback=self.parse_category_page, meta={'gender': url['gender']})

    def parse_category_page(self, response):
        product_urls = response.xpath('//a[@class="product-grid__link"]/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page, meta={'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['brand'] = self.name
        p['url'] = response.url
        p['gender'] = response.meta['gender']
        p['price'] = self.get_price(response)
        p['currency'] = self.get_currency(response)
        p['label_finder_urls'] = ["https://www.thelabelfinder.com/berlin/pinqponq/shops/DE/5235027/2950159"]
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="product-detail-slider-item"]/img/@data-flickity-lazyload').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//meta[@property="og:description"]/@content').extract_first()
        return description

    def get_color(self, name, description):
        text = name + ' ' + description
        return list(set(text.lower().split()).intersection(self.colors))

    def get_price(self, response):
        price = response.xpath('//span[@class="price"]/text()').extract_first()
        if price:
            price = price.strip()[1:]
        return float(price.strip().replace(',', ''))

    def get_currency(self, response):
        price = response.xpath('//span[@class="price"]/text()').extract_first()
        if price:
            price = price.strip()
            if price:
                return self.currency_symbol_map.get(price[0])
        return
