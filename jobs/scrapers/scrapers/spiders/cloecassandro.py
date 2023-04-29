from .generic import ShopifySpider


class CloecassandroSpider(ShopifySpider):
    name = 'Cloe Cassandro'
    collection_urls = [{"value": "https://www.cloecassandro.com/collections/all/products.json", "gender": ["women"]}]
    currency = 'GBP'
    max_pages = 5
