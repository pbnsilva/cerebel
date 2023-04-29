import scrapy
from scrapers.items import Product


class EKOSpider(scrapy.Spider):
    name = "EKO"
    allowed_domains = ["earthkindoriginals.co.uk"]
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(EKOSpider, self).__init__(*a, **kw)
        self.base_url = "https://earthkindoriginals.co.uk"
        self.urls = [
            {"value": "https://earthkindoriginals.co.uk/product-category/daywear/", "gender": ["women"]},
            {"value": "https://earthkindoriginals.co.uk/product-category/casual-dresses/", "gender": ["women"]},
            {"value": "https://earthkindoriginals.co.uk/product-category/organic-loungewear/", "gender": ["women"]},
        ]

    def start_requests(self):
        for url in self.urls:
            yield scrapy.Request(url['value'], callback=self.parse_category_page, meta={'gender': url['gender']})

    def parse_category_page(self, response):
        product_urls = response.xpath('//a[contains(@class, "woocommerce-loop-product__link")]/@href').extract()
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
        p['original_price'] = self.get_original_price(response)
        p['currency'] = self.get_currency(response)
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        if 'bundle' in name.lower():
            return
        if name.endswith('by EKO Womenswear'):
            return name[:-18]
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="woocommerce-product-gallery__image"]/a/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//meta[@property="og:description"]/@content').extract_first()
        return description

    def get_price(self, response):
        price = response.xpath('//p[contains(@class, "price")]/ins/span[contains(@class, "amount")]/text()').extract_first()
        if not price:
            price = response.xpath('//p[contains(@class, "price")]/span[@class="amount"]/text()').extract_first()
            if price:
                price = price[1:]
        if not price:
            price = response.xpath('//span[contains(@class, "woocommerce-Price-amount")]/text()').extract_first()
        if not price:
            return
        return float(price.replace(',', '.'))

    def get_original_price(self, response):
        price = response.xpath('//p[contains(@class, "price")]/del/span[contains(@class, "amount")]/text()').extract_first()
        if not price:
            return
        return float(price.replace(',', '.'))

    def get_currency(self, response):
        currency = response.xpath('//span[@class="woocommerce-Price-currencySymbol"]/text()').extract_first()
        currency = self.currency_symbol_map.get(currency)
        return currency
