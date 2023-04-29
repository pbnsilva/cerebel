import scrapy
from urllib.parse import urljoin
from scrapers.items import Product
from bs4 import BeautifulSoup


class AKindOfGuiseSpider(scrapy.Spider):
    name = "A Kind Of Guise"
    allowed_domains = ["akindofguise.com"]

    def __init__(self, *a, **kw):
        super(AKindOfGuiseSpider, self).__init__(*a, **kw)
        self.base_url = "https://akindofguise.com"
        self.max_pages = 10
        self.urls = [
            {'value': 'https://akindofguise.com/product-category/mens/accessories/', 'gender': ['men']},
            {'value': 'https://akindofguise.com/product-category/mens/jersey-knitwear/', 'gender': ['men']},
            {'value': 'https://akindofguise.com/product-category/mens/outerwear/', 'gender': ['men']},
            {'value': 'https://akindofguise.com/product-category/mens/pants/', 'gender': ['men']},
            {'value': 'https://akindofguise.com/product-category/mens/shirts/', 'gender': ['men']},
            {'value': 'https://akindofguise.com/product-category/mens/tailoring/', 'gender': ['men']},
            {'value': 'https://akindofguise.com/product-category/mens/sale-mens/', 'gender': ['men']},
            {'value': 'https://akindofguise.com/product-category/womens/accessories-womens/', 'gender': ['women']},
            {'value': 'https://akindofguise.com/product-category/womens/dresses-skirts/', 'gender': ['women']},
            {'value': 'https://akindofguise.com/product-category/womens/outerwear-womens/', 'gender': ['women']},
            {'value': 'https://akindofguise.com/product-category/womens/pants-womens/', 'gender': ['women']},
            {'value': 'https://akindofguise.com/product-category/womens/shirts-tops/', 'gender': ['women']},
            {'value': 'https://akindofguise.com/product-category/womens/sale-womens/', 'gender': ['women']},
        ]

    def start_requests(self):
        for url in self.urls:
            for p in range(self.max_pages):
                yield scrapy.Request(urljoin(url['value'], 'page/%d' % (p + 1)), callback=self.parse_category_page, meta={'gender': url['gender']})

    def parse_category_page(self, response):
        product_urls = response.xpath('.//article[@class="akog-c-product-grid-item"]/a/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page, meta={'category_page': response.url, 'gender': response.meta['gender'], 'handle_http_status_list': [301]})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['gender'] = self.get_gender(response)
        p['brand'] = self.name
        p['url'] = response.url
        p['label_finder_urls'] = ["https://www.thelabelfinder.com/berlin/a-kind-of-guise/shops/DE/1476797/2950159"]
        p['currency'] = self.get_currency(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[@itemprop="name"]/text()').extract_first()
        return name.strip()

    def get_gender(self, response):
        if '/womens/' in response.meta['category_page']:
            return 'women'
        elif '/mens/' in response.meta['category_page']:
            return 'men'
        return None

    def get_image_urls(self, response):
        urls = response.xpath('//img[@itemprop="image"]/@src').extract()
        return list(set(urls))

    def get_description(self, response):
        description = response.xpath('//div[@itemprop="description"]').extract_first()
        text = BeautifulSoup(description, 'lxml').get_text()
        return text

    def get_material(self, response):
        material = response.xpath('//div[@itemprop="description"]').re_first('\nMaterial: (.*?)\n')
        if material:
            return BeautifulSoup(material, 'lxml').get_text()

    def get_price(self, response):
        price_text = response.xpath('//meta[@itemprop="price"]/@content').extract_first()
        return float(price_text)

    def get_original_price(self, response):
        price_text = response.xpath('//div[@class="akog-c-product-detail__price"]/del/span/text()').extract_first()
        if not price_text:
            return
        return float(price_text)

    def get_currency(self, response):
        currency = response.xpath('//meta[@itemprop="priceCurrency"]/@content').extract_first()
        return currency
