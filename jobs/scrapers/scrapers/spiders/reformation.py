import scrapy
from urllib.parse import urljoin
from scrapers.items import Product


class ReformationSpider(scrapy.Spider):
    name = "Reformation"
    allowed_domains = ["www.thereformation.com"]

    def __init__(self, *a, **kw):
        super(ReformationSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.thereformation.com"
        self._max_pages = 5
        self._category_urls = [
            'https://www.thereformation.com/categories/sale',
            'https://www.thereformation.com/categories/bottoms',
            'https://www.thereformation.com/categories/jeans',
            'https://www.thereformation.com/categories/dresses',
            'https://www.thereformation.com/categories/jumpsuits',
            'https://www.thereformation.com/categories/outerwear',
            'https://www.thereformation.com/categories/intimates',
            'https://www.thereformation.com/categories/swim',
            'https://www.thereformation.com/categories/sweaters-sweatshirts',
            'https://www.thereformation.com/categories/tees',
            'https://www.thereformation.com/categories/tops',
            'https://www.thereformation.com/categories/two-pieces',
            'https://www.thereformation.com/categories/weddings-parties',
            'https://www.thereformation.com/categories/accessories',
            'https://www.thereformation.com/categories/dresses-1',
            'https://www.thereformation.com/categories/jackets',
            'https://www.thereformation.com/categories/ref-jeans-sweaters-sweatshirts',
            'https://www.thereformation.com/categories/ref-jeans-tops',
        ]

    def start_requests(self):
        for url in self._category_urls:
            for i in range(1, self._max_pages + 1):
                yield scrapy.Request(url + '?page=' + str(i), callback=self.parse_category_page)

    def parse_category_page(self, response):
        product_urls = response.xpath('//a[@class="product-summary__media-link"]/@href').extract()
        for url in product_urls:
            product_page = urljoin(self.base_url, url)
            yield scrapy.Request(product_page, callback=self.parse_product_page)

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)

        if 'veja' in p['name'].lower().split():
            return

        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['brand'] = self.name
        p['url'] = response.url
        p['gender'] = 'women'
        p['currency'] = self.get_currency(response)
        yield p

    def get_price(self, response):
        price_text = response.xpath('//meta[@itemprop="price"]/@content').extract_first()
        price = float(price_text.replace('$', ''))
        return price

    def get_original_price(self, response):
        price_text = response.xpath('//p[contains(@class, "product-prices__price--msrp")]/span/meta[@itemprop="price"]/@content').extract_first()
        if not price_text:
            return
        price = float(price_text.replace('$', ''))
        return price

    def get_currency(self, response):
        currency = response.xpath('//meta[@itemprop="priceCurrency"]/@content').extract_first()
        return currency

    def get_name(self, response):
        name = response.xpath('.//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_description(self, response):
        desc = response.xpath('.//meta[@name="description"]/@content').extract_first()
        return desc

    def get_image_urls(self, response):
        urls = response.xpath('//div[@class="product-details__image-wrapper"]/img/@data-src').extract()
        return urls

    def get_fabric(self, response):
        desc = response.xpath('//p[@class="description"]/text()').extract()
        if len(desc) > 1:
            return desc[1]
