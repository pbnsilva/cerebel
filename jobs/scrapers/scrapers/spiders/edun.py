from .generic import ShopifySpider


class EdunSpider(ShopifySpider):
    name = "Edun"
    allowed_domains = ["edun.com"]
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {'value': 'https://edun.com/collections/all/products.json', 'gender': ['women']},
    ]
