import scrapy
from urllib.parse import urljoin
from scrapers.items import Product


class HonestbySpider(scrapy.Spider):
    name = "honest by"
    allowed_domains = ["www.honestby.com"]

    def __init__(self, *a, **kw):
        super(HonestbySpider, self).__init__(*a, **kw)
        self.base_url = "http://www.honestby.com"
        self._category_urls = [
            ['women', 'http://www.honestby.com/en/category/13/dresses.html'],
            ['women', 'http://www.honestby.com/en/category/14/tops.html'],
            ['women', 'http://www.honestby.com/en/category/15/skirts.html'],
            ['women', 'http://www.honestby.com/en/category/18/trousers.html'],
            ['women', 'http://www.honestby.com/en/category/20/jackets.html'],
            ['women', 'http://www.honestby.com/en/category/21/coats.html'],
            ['women', 'http://www.honestby.com/en/category/37/shirts.html'],
            ['women', 'http://www.honestby.com/en/category/19/knitwear.html'],
            ['women', 'http://www.honestby.com/en/category/115/loungewear.html'],
            ['men', 'http://www.honestby.com/en/category/16/jackets.html'],
            ['men', 'http://www.honestby.com/en/category/17/coats.html'],
            ['men', 'http://www.honestby.com/en/category/26/jersey.html'],
            ['men', 'http://www.honestby.com/en/category/43/shirts.html'],
            ['men', 'http://www.honestby.com/en/category/44/trousers.html'],
            ['men', 'http://www.honestby.com/en/category/45/knitwear.html'],
            ['men', 'http://www.honestby.com/en/category/116/loungewear.html'],
            ['women', 'http://www.honestby.com/en/category/61/women.html'],
            ['men', 'http://www.honestby.com/en/category/88/men.html'],
            [['women', 'men'], 'http://www.honestby.com/category.php?lang=en&categoryno=92'],
        ]

    def start_requests(self):
        for gender, url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page, meta={'gender': gender})

    def parse_category_page(self, response):
        product_urls = response.xpath('.//ul[@class="overview"]/li/a/@href').extract()
        for url in product_urls:
            yield scrapy.Request(urljoin(self.base_url, url), callback=self.parse_product_page, meta={'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['brand'] = self.name
        p['url'] = response.url
        p['gender'] = response.meta['gender']
        p['price'] = self.get_price(response)
        p['currency'] = 'EUR'
        yield p

    def get_name(self, response):
        name = response.xpath('//meta[@property="og:title"]/@content').extract_first()
        return name

    def get_image_urls(self, response):
        raw_urls = response.xpath('//ul[@class="view thumbs"]/li/a/@href').extract()
        urls = []
        for url in raw_urls:
            if not url.startswith('http://'):
                urls.append(self.base_url+url)
            else:
                urls.append(url)
        return list(set(urls))

    def get_description(self, response):
        description = response.xpath('//ul[@class="info"]/li[@class="open"]/div/p/span/text()').extract_first()
        if description == "To find out more about this design, please view the description.":
            return None
        if description == "Need style advice? E-mail our Honest by style consultants\u00a0":
            return None
        return description

    def get_color(self, description):
        return list(set(description.lower().split()).intersection(self.colors))

    def get_price(self, response):
        price_text = response.xpath('//span[@id="spa-price"]/text()').extract_first()
        if not price_text:
            return
        return float(price_text.replace(',', '.').replace(' ', ''))
