from .generic import ShopifySpider


class RekhDattaSpider(ShopifySpider):
    name = "Rekh & Datta"
    allowed_domains = ["rekhdatta.com"]
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {'value': 'https://rekhdatta.com/collections/all/products.json', 'gender': ['women']},
    ]
