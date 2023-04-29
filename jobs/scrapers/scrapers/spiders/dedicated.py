import scrapy
from urllib.parse import urljoin
from scrapers.items import Product


class DedicatedSpider(scrapy.Spider):
    name = "Dedicated"
    allowed_domains = ["www.dedicatedbrand.com"]
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR', 'EUR': 'EUR'}

    def __init__(self, *a, **kw):
        super(DedicatedSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.dedicatedbrand.com"
        self._product_handles = set()
        self._category_urls = [
            ['men', 'https://www.dedicatedbrand.com/en/men/sale'],
            ['men', 'https://www.dedicatedbrand.com/en/men/t-shirts-printed'],
            ['men', 'https://www.dedicatedbrand.com/en/men/t-shirts-solid'],
            ['men', 'https://www.dedicatedbrand.com/en/men/sweatshirts-and-sweaters'],
            ['men', 'https://www.dedicatedbrand.com/en/men/hoodies'],
            ['men', 'https://www.dedicatedbrand.com/en/men/shirts'],
            ['men', 'https://www.dedicatedbrand.com/en/men/jackets'],
            ['men', 'https://www.dedicatedbrand.com/en/men/pants-and-shorts'],
            ['men', 'https://www.dedicatedbrand.com/en/men/swim-shorts'],
            ['men', 'https://www.dedicatedbrand.com/en/men/caps-and-beanies'],
            ['men', 'https://www.dedicatedbrand.com/en/men/socks'],
            ['women', 'https://www.dedicatedbrand.com/en/women/t-shirts-printed'],
            ['women', 'https://www.dedicatedbrand.com/en/women/t-shirts-solid'],
            ['women', 'https://www.dedicatedbrand.com/en/women/tops'],
            ['women', 'https://www.dedicatedbrand.com/en/women/sweatshirts-and-sweaters'],
            ['women', 'https://www.dedicatedbrand.com/en/women/dresses'],
            ['women', 'https://www.dedicatedbrand.com/en/women/shirts'],
            ['women', 'https://www.dedicatedbrand.com/en/women/pants-and-shorts'],
            ['women', 'https://www.dedicatedbrand.com/en/women/caps-and-beanies'],
            ['women', 'https://www.dedicatedbrand.com/en/women/socks'],
            ['women', 'https://www.dedicatedbrand.com/en/women/sale'],
        ]

    def start_requests(self):
        for gender, url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page, meta={'gender': gender})

    def parse_category_page(self, response):
        product_urls = response.xpath('//a[@class="productList-link"]/@href').extract()
        for url in product_urls:
            yield scrapy.Request(urljoin(self.base_url, url), callback=self.parse_product_page, meta={'gender': response.meta['gender']})

    def parse_product_page(self, response):
        # prevent duplicates
        handle = response.url.split('/')[-1]
        if handle in self._product_handles:
            return
        self._product_handles.add(handle)

        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['currency'] = self.get_currency(response)
        p['brand'] = 'Dedicated'
        p['url'] = response.url
        p['gender'] = response.meta['gender']
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//img[@class="productImages-image"]/@src').extract()
        return list(set(urls))

    def get_description(self, response):
        description = response.xpath('//meta[@property="og:description"]/@content').extract_first()
        return description

    def get_price(self, response):
        sale_price_text = response.xpath('//strong[@class="salePrice"]/text()').extract_first()
        if sale_price_text:
            return float(sale_price_text.strip().split()[0])

        price_text = response.xpath('//h2[@class="productInfo-price u-h3"]/strong/text()').extract_first()
        if not price_text:
            return

        return float(price_text.strip().split()[0])

    def get_original_price(self, response):
        sale_price_text = response.xpath('//strong[@class="salePrice"]/text()').extract_first()
        if not sale_price_text:
            return

        price_text = response.xpath('//h2[@class="productInfo-price u-h3"]/s/text()').extract_first()
        if not price_text:
            return

        price = price_text.strip().split()[0]
        return float(price)

    def get_currency(self, response):
        price_text = response.xpath('//h2[@class="productInfo-price u-h3"]/strong/text()').extract_first()
        if not price_text:
            return
        price = price_text.strip().split()[1]
        return price
