from .generic import ShopifySpider


class TriarchySpider(ShopifySpider):
    name = 'Triarchy'
    currency = 'EUR'
    max_pages = 10
    collection_urls = [
        {"value": "https://triarchy.com/collections/mens-jeans/products.json", "gender": ["men"]},
        {"value": "https://triarchy.com/collections/womens-jeans/products.json", "gender": ["women"]},
    ]
