from scrapy import Spider, Request
from scrapers.items import Product


class EknSpider(Spider):
    name = 'Ekn'
    allowed_domains = ['www.eknfootwear.com']

    def __init__(self, *a, **kw):
        super(EknSpider, self).__init__(*a, **kw)
        self.urls = [
            {'value': 'https://www.eknfootwear.com/en/shop/women/specials/sale/', 'gender': ['women']},
            {'value': 'https://www.eknfootwear.com/en/shop/men/specials/sale/', 'gender': ['men']},
            {"value": "https://www.eknfootwear.com/en/shop/women/style/boots/", "gender": ["women"]},
            {"value": "https://www.eknfootwear.com/en/shop/women/style/low-top/", "gender": ["women"]},
            {"value": "https://www.eknfootwear.com/en/shop/women/style/high-top/", "gender": ["women"]},
            {"value": "https://www.eknfootwear.com/en/shop/women/style/sandale/", "gender": ["women"]},
            {"value": "https://www.eknfootwear.com/en/shop/men/style/sandale/", "gender": ["men"]},
            {"value": "https://www.eknfootwear.com/en/shop/men/style/boots/", "gender": ["men"]},
            {"value": "https://www.eknfootwear.com/en/shop/men/style/low-top/", "gender": ["men"]},
            {"value": "https://www.eknfootwear.com/en/shop/men/style/low-top/", "gender": ["men"]},
        ]
        self.label_finder_urls = ["https://www.thelabelfinder.com/berlin/ekn/shops/DE/3221066/2950159"]

    def start_requests(self):
        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender'], 'label_finder_urls': self.label_finder_urls})

    def parse_store(self, response):
        urls = response.xpath('//a[@class="product--title"]/@href').extract()
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
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = []
        for url in response.xpath('//img[@itemprop="image"]/@srcset').extract():
            if ',' in url:
                url = url.split(',')[0]
            urls.append(url)
        return urls

    def get_description(self, response):
        description = response.xpath('//meta[@property="og:description"]/@content').extract_first()
        return description

    def get_price(self, response):
        price = response.xpath('//meta[@itemprop="price"]/@content').extract_first()
        return float(price)

    def get_original_price(self, response):
        price = response.xpath('//span[@class="price--line-through"]/text()').extract_first()
        if not price:
            return
        return float(price[3:])

    def get_currency(self, response):
        currency = response.xpath('//meta[@itemprop="priceCurrency"]/@content').extract_first()
        return currency
