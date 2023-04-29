from .generic import ShopifySpider


class UpstateSpider(ShopifySpider):
    name = "Upstate"
    allowed_domains = ["youreupstate.com"]
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {'value': 'https://youreupstate.com/collections/all/products.json', 'gender': ['women']},
    ]
