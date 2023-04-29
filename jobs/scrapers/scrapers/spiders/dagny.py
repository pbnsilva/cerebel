from .generic import ShopifySpider


class DagnySpider(ShopifySpider):
    name = 'Dagny'
    currency = 'GBP'
    max_pages = 20
    collection_urls = [
        {"value": "https://dagnylondon.com/collections/all/products.json", "gender": ["women"]},
    ]
