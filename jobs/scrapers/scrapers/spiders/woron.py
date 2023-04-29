from .generic import ShopifySpider


class WoronSpider(ShopifySpider):
    name = 'Woron'
    currency = 'DKK'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.woronstore.com/collections/all/products.json", "gender": ["women"]},
    ]
