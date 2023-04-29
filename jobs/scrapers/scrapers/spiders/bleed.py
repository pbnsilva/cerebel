import scrapy
from scrapers.items import Product


class BleedSpider(scrapy.Spider):
    name = "bleed"
    allowed_domains = ["www.bleed-clothing.com"]

    def __init__(self, *a, **kw):
        super(BleedSpider, self).__init__(*a, **kw)
        self.base_url = "https://www.bleed-clothing.com"
        self._category_urls = [
            [['men'], 'https://www.bleed-clothing.com/english/shop-men/t-shirts-tanks'],
            [['men'], 'https://www.bleed-clothing.com/english/shop-men/longsleeves'],
            [['men'], 'https://www.bleed-clothing.com/english/shop-men/shirts'],
            [['men'], 'https://www.bleed-clothing.com/english/shop-men/sweater'],
            [['men'], 'https://www.bleed-clothing.com/english/shop-men/hoodies-zip-hoodies'],
            [['men'], 'https://www.bleed-clothing.com/english/shop-men/knitwear'],
            [['men'], 'https://www.bleed-clothing.com/english/shop-men/jeans-pants'],
            [['men'], 'https://www.bleed-clothing.com/english/shop-men/shorts'],
            [['men'], 'https://www.bleed-clothing.com/english/shop-men/jackets'],
            [['women'], 'https://www.bleed-clothing.com/english/shop-women/t-shirts-tops'],
            [['women'], 'https://www.bleed-clothing.com/english/shop-women/longsleeves'],
            [['women'], 'https://www.bleed-clothing.com/english/shop-women/shirts-blouses'],
            [['women'], 'https://www.bleed-clothing.com/english/shop-women/sweater'],
            [['women'], 'https://www.bleed-clothing.com/english/shop-women/hoodies-zip-hoodies'],
            [['women'], 'https://www.bleed-clothing.com/english/shop-women/knitwear'],
            [['women'], 'https://www.bleed-clothing.com/english/shop-women/jeans-pants'],
            [['women'], 'https://www.bleed-clothing.com/english/shop-women/shorts'],
            [['women'], 'https://www.bleed-clothing.com/english/shop-women/dresses-skirts'],
            [['women'], 'https://www.bleed-clothing.com/english/shop-women/jackets'],
            [['women', 'men'], 'https://www.bleed-clothing.com/english/accessories/belts'],
            [['women', 'men'], 'https://www.bleed-clothing.com/english/accessories/wallets'],
            [['women', 'men'], 'https://www.bleed-clothing.com/english/accessories/socks'],
            [['women', 'men'], 'https://www.bleed-clothing.com/english/accessories/gloves'],
            [['women', 'men'], 'https://www.bleed-clothing.com/english/accessories/bags'],
            [['women', 'men'], 'https://www.bleed-clothing.com/english/accessories/beanies'],
            [['women', 'men'], 'https://www.bleed-clothing.com/english/accessories/caps'],
            [['women', 'men'], 'https://www.bleed-clothing.com/english/accessories/headbands'],
            [['women', 'men'], 'https://www.bleed-clothing.com/english/accessories/scarves'],
        ]
        self._stores = [
            {'name': 'LOVECO', 'address': 'Sonntagstraße 29', 'postal_code': '10245', 'city': 'Berlin', 'country': 'Germany', 'location': {'lat': 52.505984, 'lon': 13.465904}},
            {'name': 'supermarché', 'address': 'Wiener Straße 16', 'postal_code': '10999', 'city': 'Berlin', 'country': 'Germany', 'location': {'lat': 52.4976298, 'lon': 13.4277943}},
        ]

    def start_requests(self):
        for gender, url in self._category_urls:
            yield scrapy.Request(url, callback=self.parse_category_page, meta={'gender': gender})

    def parse_category_page(self, response):
        product_urls = response.xpath('//p[@class="product-name"]/a/@href').extract()
        for url in product_urls:
            yield scrapy.Request(url, callback=self.parse_product_page, meta={'gender': response.meta['gender']})

    def parse_product_page(self, response):
        p = Product()
        p['name'] = self.get_name(response)
        p['description'] = self.get_description(response)
        p['image_url'] = self.get_image_urls(response)
        p['brand'] = self.name
        p['url'] = response.url
        p['gender'] = response.meta['gender']
        p['price'] = self.get_price(response)
        p['original_price'] = self.get_original_price(response)

        # bleed always shows an old-price even if item is not on sale
        if p['price'] == p['original_price']:
            p['original_price'] = None

        p['currency'] = 'EUR'
        p['stores'] = self._stores
        p['label_finder_urls'] = ["https://www.thelabelfinder.com/berlin/bleed/shops/DE/1478487/2950159"]
        yield p

    def get_name(self, response):
        name = response.xpath('//h1[@class="product-name-h1"]/text()').extract_first()
        return name.strip()

    def get_image_urls(self, response):
        urls = response.xpath('//a[@class="rsImg"]/@href').extract()
        return list(set(urls))

    def get_description(self, response):
        description = response.xpath('//p[@class="bleed-desc"]/text()').extract_first()
        return description

    def get_price(self, response):
        price = response.xpath('//meta[@property="product:price:amount"]/@content').extract_first()
        return float(price.strip())

    def get_original_price(self, response):
        price = response.xpath('//p[@class="old-price"]//span[@class="price"]/text()').extract_first()
        if not price:
            return
        return float(price.strip()[1:])
