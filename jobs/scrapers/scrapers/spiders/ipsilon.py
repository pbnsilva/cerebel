from .generic import ShopifySpider


class IpsilonSpider(ShopifySpider):
    name = "Ipsilon"
    allowed_domains = ["ipsilonparis.com"]
    currency = 'EUR'
    max_pages = 2
    collection_urls = [
        {'value': 'https://ipsilonparis.com/collections/all/products.json', 'gender': ['women']},
    ]
