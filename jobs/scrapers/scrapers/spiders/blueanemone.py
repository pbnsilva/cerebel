from .generic import ShopifySpider


class BlueAnemoneSpider(ShopifySpider):
    name = "Blue Anemone"
    allowed_domains = ["blueanemone.com"]
    currency = 'EUR'
    max_pages = 20
    collection_urls = [
        {'value': 'https://blueanemone.com/collections/all/products.json', 'gender': ['women']},
    ]
