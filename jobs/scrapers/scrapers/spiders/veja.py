from scrapy import Spider, Request
from scrapers.items import Product
from bs4 import BeautifulSoup


class VejaSpider(Spider):
    name = 'Veja'
    allowed_domains = ['veja-store.com']

    def __init__(self, *a, **kw):
        super(VejaSpider, self).__init__(*a, **kw)
        self._max_pages = 4
        self.urls = [
            {"value": "http://www.veja-store.com/en/6-men", "gender": ["men"], "tags": ["sneakers"]},
            {"value": "http://www.veja-store.com/en/17-women", "gender": ["women"], "tags": ["sneakers"]},
        ]
        self.label_finder_urls = ["https://www.thelabelfinder.com/berlin/veja/shops/DE/34844/2950159"]

    def start_requests(self):
        for i in range(1, self._max_pages+1):
            for url in self.urls:
                url_val = url['value'] + '?p=' + str(i)
                yield Request(url_val, callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender'], 'tags': url['tags']})

    def parse_store(self, response):
        urls = response.xpath('//a[@class="product_img_link"]/@href').extract()
        for url in urls:
            yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender'], 'tags': response.meta['tags']})

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
        p['label_finder_urls'] = self.label_finder_urls
        p['tags'] = self._get_tags(p['description'], response.meta['tags'])
        yield p

    def _get_tags(self, description, tags):
        desc = description.lower()
        if 'wallet' in desc:
            return 'wallets'
        elif 'bags' in desc:
            return 'bags'
        return tags

    def get_name(self, response):
        name = response.xpath('//meta[@itemprop="name"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//li[@class="thumbnail-pic"]/a/@href').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="product-block__content"]//p').extract()
        return '\n'.join([BeautifulSoup(desc.replace('<br>', '\n'), 'lxml').text.strip() for desc in description])

    def get_price(self, response):
        price = response.xpath('//meta[@itemprop="price"]/@content').extract_first()
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//meta[@itemprop="currency"]/@content').extract_first()
        return currency
