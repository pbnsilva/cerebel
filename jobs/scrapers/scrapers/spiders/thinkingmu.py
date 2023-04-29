from scrapy import Spider, Request
from scrapers.items import Product


class ThinkingmuSpider(Spider):
    name = 'Thinking Mu'

    def __init__(self, *a, **kw):
        super(ThinkingmuSpider, self).__init__(*a, **kw)
        self.urls = [
            {"value": "http://thinkingmu.com/en/10-he/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/11-she/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/12-t-shirts/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/33-shirts/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/78-polo/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/14-pants/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/79-shorts/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/63-hempflowers/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/13-sweatshirts/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/54-knitwear/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/56-swimwear/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/64-basics/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/15-boxers/", "gender": ["men"]},
            {"value": "http://thinkingmu.com/en/29-bags/", "gender": ["women", "men"]},
            {"value": "http://thinkingmu.com/en/60-beach-wraps/", "gender": ["women", "men"]},
            {"value": "http://thinkingmu.com/en/17-tops/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/35-shirts/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/18-sweatshirts/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/20-pants/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/55-knitwear/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/57-skirts/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/58-jumpsuits/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/59-shorts/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/80-apres-yoga/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/26-dresses/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/65-hempflowers/", "gender": ["women"]},
            {"value": "http://thinkingmu.com/en/66-basics/", "gender": ["women"]},
        ]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender']})

    def parse_store(self, response):
        urls = response.xpath('//a[contains(@class, "product_img_link")]/@href').extract()
        for url in urls:
            yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender']})

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
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[@itemprop="name"]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//img[@itemprop="image"]/@src').extract()
        urls += response.xpath('//img[contains(@class, "product-image-wrap")]/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="product-descr"]/p/text()').extract_first()
        return description

    def get_price(self, response):
        price = response.xpath('//span[@itemprop="price"]/@content').extract_first()
        return float(price)

    def get_original_price(self, response):
        price = response.xpath('//span[@id="old_price_display"]/span/text()').extract_first()
        if not price:
            return
        return float(price.split()[0].replace(',', '.'))

    def get_currency(self, response):
        currency = response.xpath('//meta[@itemprop="priceCurrency"]/@content').extract_first()
        return currency
