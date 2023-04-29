from .generic import ShopifySpider


class ThundersloveSpider(ShopifySpider):
    name = 'ThundersLove'
    currency = 'EUR'
    max_pages = 20
    collection_urls = [
        {"value": "https://www.thunderslove.com/collections/all/products.json", "gender": ["men", "women"]},
    ]
