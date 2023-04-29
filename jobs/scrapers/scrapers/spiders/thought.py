import json
import scrapy
from scrapers.items import Product
from bs4 import BeautifulSoup
from urllib.parse import quote_plus


class ThoughtSpider(scrapy.Spider):
    name = "Thought"
    allowed_domains = ["www.wearethought.com"]
    custom_settings = {
        'AUTOTHROTTLE_ENABLED': True,
        'AUTOTHROTTLE_START_DELAY': 5,
        'AUTOTHROTTLE_MAX_DELAY': 60,
        'AUTOTHROTTLE_TARGET_CONCURRENCY': 1.0,
    }

    def __init__(self, *a, **kw):
        super(ThoughtSpider, self).__init__(*a, **kw)
        self._max_pages = 15
        self._product_names = set()  # prevent duplicates
        self._category_urls = [
            {'value': 'https://www.wearethought.com/clothing-sale/womens/', 'gender': ['women']},
            {'value': 'https://www.wearethought.com/clothing-sale/mens/', 'gender': ['men']},
            {'value': 'https://www.wearethought.com/women/womens-clothing-all/', 'gender': ['women']},
            {'value': 'https://www.wearethought.com/mens/mens-clothing-all/', 'gender': ['men']},
            {'value': 'https://www.wearethought.com/sustainable-socks/womens/', 'gender': ['women']},
            {'value': 'https://www.wearethought.com/sustainable-socks/mens/', 'gender': ['men']},
            {'value': 'https://www.wearethought.com/accessories/womens-accessories/', 'gender': ['women']},
            {'value': 'https://www.wearethought.com/accessories/mens-accessories/', 'gender': ['men']},
        ]

    def start_requests(self):
        for url in self._category_urls:
            for i in range(1, self._max_pages + 1):
                yield scrapy.Request(url['value'] + '?product_list_limit=72&p=' + str(i), callback=self.parse_category_page, meta={'gender': url['gender']})

    def parse_category_page(self, response):
        product_urls = response.xpath('//a[@class="product-item-link"]/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page, meta=response.meta)

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        if p['name'] in self._product_names:
            return
        self._product_names.add(p['name'])
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['brand'] = self.name
        p['url'] = self.get_affiliate_link(response.url)
        p['gender'] = response.meta['gender']
        p['currency'] = self.get_currency(response)
        yield p

    def get_affiliate_link(self, url):
        return 'https://click.linksynergy.com/deeplink?id=VTA2/22Mkg4&mid=39253&murl=%s' % quote_plus(url)

    def get_price(self, response):
        price_text = response.xpath('//meta[@itemprop="price"]/@content').extract_first()
        price = float(price_text.replace('$', ''))
        return price

    def get_original_price(self, response):
        price = response.xpath('//span[@data-price-type="oldPrice"]/@data-price-amount').extract_first()
        if not price:
            return
        return float(price)

    def get_currency(self, response):
        currency = response.xpath('//meta[@property="product:price:currency"]/@content').extract_first()
        return currency

    def get_name(self, response):
        name = response.xpath('//span[@itemprop="name"]/text()').extract_first()
        return name

    def get_description(self, response):
        desc = response.xpath('//div[contains(@class, "description")]').extract()
        return BeautifulSoup(desc[0], 'lxml').text.strip()

    def get_image_urls(self, response):
        data = response.xpath('//script[@type="text/x-magento-init"]/text()').extract()
        if not data:
            return

        urls = set()
        for val in data:
            data = json.loads(val)
            if '[data-role=swatch-options]' in data:
                image_data = data['[data-role=swatch-options]']['Magento_Swatches/js/configurable-customer-data']['swatchOptions']['images']
                for k in image_data:
                    for v in image_data[k]:
                        urls.add(v['full'])
                if len(urls) > 0:
                    break
            elif '[data-gallery-role=gallery-placeholder]' in data:
                image_data = data['[data-gallery-role=gallery-placeholder]']['mage/gallery/gallery']['data']
                for v in image_data:
                    urls.add(v['full'])
                if len(urls) > 0:
                    break

        return list(urls)
