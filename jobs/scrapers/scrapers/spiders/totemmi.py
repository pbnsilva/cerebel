from .generic import ShopifySpider


class TotemmiSpider(ShopifySpider):
    name = 'Totemmi'
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {"value": "https://www.totemmi.com/collections/all/products.json", "gender": ["women"]},
    ]
