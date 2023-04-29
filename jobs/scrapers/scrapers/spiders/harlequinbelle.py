from .generic import ShopifySpider


class HarlequinBelleSpider(ShopifySpider):
    name = 'Harlequin Belle'
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {"value": "https://www.harlequinbelle.com/collections/all/products.json", "gender": ["women"]},
    ]
