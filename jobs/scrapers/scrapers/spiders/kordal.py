from .generic import ShopifySpider


class KordalSpider(ShopifySpider):
    name = "Kordal"
    currency = 'USD'
    allowed_domains = ["kordalstudio.com"]
    max_pages = 10
    collection_urls = [
        {'value': 'https://kordalstudio.com/collections/all/products.json', 'gender': ['women']},
    ]
