from .generic import ShopifySpider


class RhumaaSpider(ShopifySpider):
    name = "Rhumaa"
    allowed_domains = ["www.rhumaa.com"]
    currency = 'EUR'
    max_pages = 10
    collection_urls = [
        {'value': 'https://www.rhumaa.com/collections/woman/products.json', 'gender': ['women']},
        {'value': 'https://www.rhumaa.com/collections/male/products.json', 'gender': ['men']},
    ]
