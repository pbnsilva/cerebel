import scrapy
from urllib.parse import urljoin
from bs4 import BeautifulSoup
from scrapers.items import Product


class SezaneSpider(scrapy.Spider):
    name = "Sezane"
    allowed_domains = ["www.sezane.com"]

    def __init__(self, *a, **kw):
        super(SezaneSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.sezane.com"
        self._category_urls = [
            'https://www.sezane.com/en/e-shop/spring-collection-leathergoods-leathergoods',
            'https://www.sezane.com/en/e-shop/spring-collection-leathergoods-small-leathergoods',
            'https://www.sezane.com/en/e-shop/spring-collection-leathergoods-baskets',
            'https://www.sezane.com/en/e-shop/spring-collection-shoes-flats',
            'https://www.sezane.com/en/e-shop/spring-collection-shoes-low-heels',
            'https://www.sezane.com/en/e-shop/spring-collection-shoes-high-heels',
            'https://www.sezane.com/en/e-shop/spring-collection-tops-blouses',
            'https://www.sezane.com/en/e-shop/spring-collection-tops-shirts',
            'https://www.sezane.com/en/e-shop/spring-collection-tops-t-shirts',
            'https://www.sezane.com/en/e-shop/spring-collection-dresses',
            'https://www.sezane.com/en/e-shop/spring-collection-bottoms',
            'https://www.sezane.com/en/e-shop/spring-collection-knitwear',
            'https://www.sezane.com/en/e-shop/spring-collection-jackets',
            'https://www.sezane.com/en/e-shop/spring-collection-denim',
            'https://www.sezane.com/en/e-shop/spring-collection-jewellery-rings',
            'https://www.sezane.com/en/e-shop/spring-collection-jewellery-earrings',
            'https://www.sezane.com/en/e-shop/spring-collection-jewellery-bracelets',
            'https://www.sezane.com/en/e-shop/spring-collection-jewellery-necklaces',
            'https://www.sezane.com/en/e-shop/spring-collection-accessories',
            'https://www.sezane.com/en/e-shop/la-liste',
        ]

    def start_requests(self):
        for url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page,
                                 meta={'dont_redirect': True, 'handle_httpstatus_list': [302, 301]},
                                 headers={'Accept-Language': 'en-GB,en;q=0.9,en-US;q=0.8,de;q=0.7,pt;q=0.6'},
                                 cookies={'X-Mapping-fplgdikb': '08E18117EA8015B5DC40B37A76C9CC1D', 'djvsez20180902': 'runiso', 'Sezane': 'SiteDevise=2', 'PrehomeNew': 1, 'Prehome': 1})

    def parse_category_page(self, response):
        product_urls = response.xpath('//a[contains(@class, "free-productLink")]/@href').extract()
        for url in product_urls:
            yield scrapy.Request(urljoin(self.base_url, url), callback=self.parse_product_page,
                                 headers={'Accept-Language': 'en-GB,en;q=0.9,en-US;q=0.8,de;q=0.7,pt;q=0.6'},
                                 cookies={'X-Mapping-fplgdikb': '08E18117EA8015B5DC40B37A76C9CC1D', 'djvsez20180902': 'runiso', 'Sezane': 'SiteDevise=2', 'PrehomeNew': 1, 'Prehome': 1})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['description_html'] = self.get_description_html(response)
        p['image_url'] = self.get_image_urls(response)
        p['price'], p['currency'] = self.get_price_and_currency(response)
        p['brand'] = self.name
        p['url'] = response.url
        p['gender'] = ['women']
        yield p

    def get_name(self, response):
        name = response.xpath('//span[@id="MainContentPlaceHolder_litNomModele"]/text()').extract_first()
        return name

    def get_image_urls(self, response):
        urls = response.xpath('//img[@class="product-page__visuals__slider__img"]/@src').extract()
        return urls

    def get_description(self, response):
        description = response.xpath('//div[@class="product-page__main__text__container"]').extract_first()
        if not description:
            return
        text = BeautifulSoup(description.replace('<br>', '\n').replace('<br/>', '\n'), 'lxml').get_text().strip()

        if not text:
            description = response.xpath('//div[@id="MainContentPlaceHolder_bulletPointDiv"]').extract_first()
        if not description:
            return
        text = BeautifulSoup(description.replace('<br>', '\n').replace('<br/>', '\n'), 'lxml').get_text().strip()

        return text

    def get_description_html(self, response):
        description = response.xpath('//div[@class="product-page__main__text__container"]').extract_first()
        if not description:
            description = response.xpath('//div[@id="MainContentPlaceHolder_bulletPointDiv"]').extract_first()
        return description

    def get_price_and_currency(self, response):
        price = response.xpath('//div[@class="product-page__price"]/text()').extract_first()
        if not price:
            return None, None
        price = price.replace('\n', '').replace('\r', '').strip().replace(',', '')
        if '€' in price:
            return float(price[:-1]), 'EUR'
        elif '£' in price:
            return float(price[1:]), 'GBP'
