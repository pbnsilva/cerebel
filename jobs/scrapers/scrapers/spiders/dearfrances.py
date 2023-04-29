from .generic import ShopifySpider


class DearFrancesSpider(ShopifySpider):
    name = 'Dear Frances'
    currency = 'USD'
    max_pages = 20
    trim_border = True
    collection_urls = [
        {"value": "https://dearfrances.com/collections/all/products.json", "gender": ["women"]},
    ]
