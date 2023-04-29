from .generic import ShopifySpider


class MartinAsbjornSpider(ShopifySpider):
    name = "Martin Asbjorn"
    allowed_domains = ["www.martinasbjorn.com"]
    currency = 'EUR'
    max_pages = 10
    collection_urls = [
        {'value': 'https://www.martinasbjorn.com/collections/all/products.json', 'gender': ['women']},
    ]
