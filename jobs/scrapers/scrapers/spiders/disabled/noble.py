from .generic import ShopifySpider


class NobleSpider(ShopifySpider):
    name = 'Noble'
    currency = 'USD'
    max_pages = 10
    collection_urls = [{"value": "https://nobledenim.com/collections/all/products.json", "gender": ["men"]}]
