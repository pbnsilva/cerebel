import scrapy
from scrapers.items import Product
from urllib.parse import urljoin
from bs4 import BeautifulSoup
from urllib.parse import quote_plus


class PeopleTreeSpider(scrapy.Spider):
    name = "People Tree"
    allowed_domains = ["www.peopletree.co.uk"]
    currency_symbol_map = {'£': 'GBP', '$': 'USD', '€': 'EUR'}

    def __init__(self, *a, **kw):
        super(PeopleTreeSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.peopletree.co.uk"
        self._slugs = set()
        self._category_urls = [
            {'value': 'https://www.peopletree.co.uk/women/new-in', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/knitwear', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/dresses', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/trousers', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/jumpsuits', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/jackets-', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/skirts', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/tops', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/accessories', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/underwear', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/active-wear', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/footwear', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/nightwear', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/women/jewellery', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/knitwear', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/party-wear', 'gender': ['women']},
            {'value': 'https://www.peopletree.co.uk/essentials', 'gender': ['women']},
        ]

    def start_requests(self):
        for url in self._category_urls:
            yield scrapy.Request(url['value'], callback=self.parse_category_page,
                                 meta={'gender': url['gender'], 'dont_redirect': True, "handle_httpstatus_list": [302]},
                                 headers={'Accept-Language': 'en-GB,en;q=0.9,en-US;q=0.8,de;q=0.7,pt;q=0.6', 'Host': 'www.peopletree.co.uk'},
                                 cookies={'skip-icept-redirect': True, 'ASP.NET_SessionId': 'beij1uu13nqd0oeqaegouhlb', 'Currency': 3, '_ems_visitor': '1784147400.987218163', 'session-set': True, 'cookieconsent_status': 'dismiss', '_ems_session': '1784147400.188290386'})

    def parse_category_page(self, response):
        product_urls = response.xpath('//div[contains(@class, "product-image")]/a/@href').extract()
        for url in product_urls:
            slug = url.split('/')[-1]
            if slug in self._slugs:
                continue
            self._slugs.add(slug)
            yield scrapy.Request(urljoin(self.base_url, url), callback=self.parse_product_page)

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['brand'] = self.name
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)
        p['url'] = 'https://click.linksynergy.com/deeplink?id=VTA2/22Mkg4&mid=39802&murl=%s' % quote_plus(response.url)
        p['gender'] = 'women'
        p['currency'] = self.get_currency(response)
        yield p

    def get_name(self, response):
        name = response.xpath('//h2[@class="pdp-title"]/span/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//div[contains(@class, "desktop-images")]//img/@src').extract()
        return [urljoin(self.base_url, u) for u in urls]

    def get_description(self, response):
        description = response.xpath('//div[@class="pdp-descript"]').extract_first()
        if not description:
            return
        return BeautifulSoup(description, 'lxml').text

    def get_price(self, response):
        price = response.xpath('//meta[@property="product:price:amount"]/@content').extract_first()
        if not price:
            return
        return float(price)

    def get_original_price(self, response):
        price = response.xpath('//h6[@class="pdp-old-price"]/text()').extract_first()
        if not price:
            return
        return float(price[1:])

    def get_currency(self, response):
        currency = response.xpath('//meta[@property="product:price:currency"]/@content').extract_first()
        return currency
