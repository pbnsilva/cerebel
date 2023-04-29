from .generic import ShopifySpider


class MatterSpider(ShopifySpider):
    name = 'Matter'
    max_pages = 5
    currency = 'USD'
    collection_urls = [
        {'value': 'https://shop.matterprints.com/collections/all/products.json', 'gender': ['women']},
    ]
