import re
from html import unescape
from scrapy import Spider, Request
from urllib.parse import urljoin, urlparse
from scrapers.items import Product


class CorabellottoSpider(Spider):
    name = 'Cora Bellotto'
    allowed_domains = []
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(CorabellottoSpider, self).__init__(*a, **kw)
        self._pagination_pattern = re.compile('^https?:.*[\\?&]page=\\d{1}$')
        self.urls = [{"value": "http://corabellotto.tictail.com/products/dresses", "gender": ["women"]}, {"value": "http://corabellotto.tictail.com/products/blouses", "gender": ["women"]}, {"value": "http://corabellotto.tictail.com/products/bottoms", "gender": ["women"]}]
        self.label_finder_urls = []

    def start_requests(self):

        for url in self.urls:
            yield Request(url['value'], callback=self.parse_store, meta={'brand': self.name, 'gender': url['gender'], 'label_finder_urls': self.label_finder_urls})

    def parse_store(self, response):
        url_parse = urlparse(response.url)
        base_url = '%s://%s' % (url_parse.scheme, url_parse.netloc)
        self.allowed_domains.append(url_parse.netloc)
        product_urls = response.xpath('//a/@href').extract()
        for url in product_urls:
            if not self._is_valid_url(url):
                continue
            url = urljoin(base_url, url)
            if self._is_pagination_url(url):
                yield Request(url, callback=self.parse_store, meta={'brand': response.meta['brand'], 'gender': response.meta['gender'], 'label_finder_urls': response.meta['label_finder_urls']})
            else:
                yield Request(url, callback=self.parse_product_page, meta={'brand': response.meta['brand'], 'gender': response.meta['gender'], 'label_finder_urls': response.meta['label_finder_urls']})

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
        if response.meta['label_finder_urls']:
            p['label_finder_urls'] = response.meta['label_finder_urls']
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//img[@class="productImages-image"]/@src').extract()
        if not urls:
            urls = response.xpath('//ul[contains(@class, "product-images")]//img/@src').extract()
        if not urls:
            urls = response.xpath('//div[contains(@class, "ProductItem-gallery-slides-item")]//img/@data-src').extract()
        if not urls:
            urls = response.xpath('//meta[@property="og:image:secure_url"]/@content').extract()
        if not urls:
            urls = response.xpath('//meta[@property="og:image"]/@content').extract()
        return self._fix_urls(urls)

    def get_description(self, response):
        description = response.xpath('//meta[@property="og:description"]/@content').extract_first()
        if not description:
            return
        return unescape(description)

    def get_price(self, response):
        price = response.xpath('//meta[@property="og:price:amount"]/@content').extract_first()
        if not price:
            price = response.xpath('//meta[@property="product:price:amount"]/@content').extract_first()
        if not price:
            price = response.xpath('//meta[@itemprop="price"]/@content').extract_first()
        if not price:
            price = response.xpath('//span[@itemprop="price"]/@content').extract_first()
        if not price:
            price = response.xpath('//p[@itemprop="price"]/@content').extract_first()
        if not price:
            price = response.xpath('//p[@class!="cart-prod-subtotal"]//span[@class="woocommerce-Price-amount amount"]/text()').extract_first()
            if price:
                price = price.replace(',', '.')
        if not price:
            price = response.xpath('//span[contains(@class, "price_tag")]/text()').extract_first()
        if not price:
            price = response.xpath('//span[@class="price"]/text()').extract_first()
            if price:
                price = price.strip()[1:]
        if not price:
            price = response.xpath('//h2[contains(@class, "productInfo-price")]/strong/text()').extract_first()
            if price:
                price = price.split()[0]
        if not price:
            return
        try:
            price = float(price.strip().replace(',', '.'))
        except ValueError:
            return
        return price

    def get_currency(self, response):
        currency = response.xpath('//meta[@property="og:price:currency"]/@content').extract_first()
        if not currency:
            currency = response.xpath('//meta[@property="product:price:currency"]/@content').extract_first()
        if not currency:
            currency = response.xpath('//span[@class="woocommerce-Price-currencySymbol"]/text()').extract_first()
            if currency:
                currency = self.currency_symbol_map.get(currency)
        if not currency:
            currency = response.xpath('//meta[@itemprop="currency"]/@content').extract_first()
        if not currency:
            currency = response.xpath('//meta[@itemprop="priceCurrency"]/@content').extract_first()
        if not currency:
            currency = response.xpath('//span[contains(@class, "currency")]/text()').extract_first()
        if not currency:
            price = response.xpath('//span[@class="price"]/text()').extract_first()
            if price:
                price = price.strip()
                if price:
                    currency = self.currency_symbol_map.get(price[0])
        if not currency:
            currency = response.xpath('//h2[contains(@class, "productInfo-price")]/strong/text()').extract_first()
            if currency:
                currency = currency.split()[1]
        if not currency:
            return
        return currency

    def _is_valid_url(self, url):
        return not url.startswith('mailto:') and not url.startswith('javascript:')

    def _is_pagination_url(self, url):
        return self._pagination_pattern.match(url) is not None

    def _fix_urls(self, urls):
        new_urls = []
        for u in urls:
            if not u.startswith('http'):
                u = 'http:' + u
            new_urls.append(u)
        return new_urls
