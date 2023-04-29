import scrapy
from urllib.parse import urljoin
from bs4 import BeautifulSoup
from scrapy.selector import Selector


class IconicSpider(scrapy.Spider):
    name = "Iconic"
    allowed_domains = ["www.theiconic.com.au"]
    # custom_settings = {
    #     'AUTOTHROTTLE_ENABLED': True,
    #     'AUTOTHROTTLE_START_DELAY': 5,
    #     'AUTOTHROTTLE_TARGET_CONCURRENCY': 6,
    # }

    def __init__(self, *a, **kw):
        super(IconicSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.theiconic.com.au"

    def start_requests(self):
        yield scrapy.Request(self.base_url, callback=self.parse_main_page)

    def parse_main_page(self, response):
        headers = response.xpath('//a[@data-ga-category="Header Navigation"]').extract()
        for h in headers:
            s = Selector(text=h)
            if s.xpath('//@data-ga-action').extract_first() not in {'Clothing', 'Shoes', 'Accessories'}:
                continue

            url = urljoin(self.base_url, s.xpath('//@href').extract_first())
            gender = None
            if 'womens' in url:
                gender = 'women'
            elif 'mens' in url:
                gender = 'men'

            if not gender:
                continue

            yield scrapy.Request(url, callback=self.parse_facets)
            # yield scrapy.Request(url, callback=self.parse_products, meta={'gender': gender})

    def parse_products(self, response):
        product_urls = response.xpath('//a[contains(@class, "product-details")]/@href').extract()
        for url in product_urls:
            yield scrapy.Request(urljoin(self.base_url, url), callback=self.parse_product_page, meta={'gender': response.meta['gender'], 'cat_url': response.url.split('?')[0]})

        next_page = response.xpath('//link[@rel="next"]/@href').extract_first()
        if next_page:
            yield scrapy.Request(next_page, callback=self.parse_products, meta={'gender': response.meta['gender']})

    def parse_facets(self, response):
        facets = response.xpath('//div[contains(@class, "facet")]//input').extract()
        for f in facets:
            s = Selector(text=f)
            name = s.xpath('//@name').extract_first()
            if name not in {'category', 'colour', 'fabric_material', 'occasion', 'shape_fit', 'sporttype'}:
                continue
            value = s.xpath('//@value').extract_first()
            label = value
            if name == 'category':
                label = s.xpath('//@id').extract_first()
            yield scrapy.Request('%s?page=1&%s=%s' % (response.url, name, value),
                                 callback=self.parse_faceted_page,
                                 meta={'attribute_name': name,
                                       'attribute_label': label,
                                       'attribute_value': value})

    def parse_faceted_page(self, response):
        product_urls = response.xpath('//a[contains(@class, "product-details")]/@href').extract()
        urls = [u for u in product_urls]
        if not urls:
            return
        yield {
            'attribute_name': response.meta['attribute_name'],
            'attribute_value': response.meta['attribute_label'],
            'urls': urls,
        }

        next_page = response.xpath('//link[@rel="next"]/@href').extract_first()
        if next_page:
            yield scrapy.Request(next_page, callback=self.parse_faceted_page, meta={'attribute_name': response.meta['attribute_name'],
                                                                                    'attribute_value': response.meta['attribute_value'],
                                                                                    'attribute_label': response.meta['attribute_label']})

    def parse_product_page(self, response):
        p = {
            'url': response.url,
            'cat_url': response.meta['cat_url'],
            'name': response.xpath('//h1[@itemprop="name"]/text()').extract_first().strip(),
            'brand': response.xpath('//a[@itemprop="brand"]/@content').extract_first().strip(),
            'description': BeautifulSoup(response.xpath('//div[contains(@class, "product-description")]').extract_first(), 'lxml').text.strip(),
            'gender': response.meta['gender'],
        }

        yield p
