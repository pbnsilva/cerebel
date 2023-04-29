from .generic import ShopifySpider


class CharlieFeistSpider(ShopifySpider):
    name = 'Charlie Feist'
    currency = 'GBP'
    max_pages = 20
    collection_urls = [
        {"value": "https://charliefeist.com/collections/all/products.json", "gender": ["women", "men"]},
    ]
