from .generic import ShopifySpider


class JeckybengSpider(ShopifySpider):
    name = 'JeckyBeng'
    currency = 'EUR'
    max_pages = 10
    collection_urls = [{"value": "https://shop.jeckybeng.com/collections/all/products.json", "gender": ["men"]}]
