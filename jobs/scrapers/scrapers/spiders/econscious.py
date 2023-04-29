from .generic import ShopifySpider


class EconsciousSpider(ShopifySpider):
    name = 'Econscious'
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {"value": "https://www.econscious.net/collections/organic-mens-clothing/products.json", "gender": ["men"]},
        {"value": "https://www.econscious.net/collections/organic-womens-clothing/products.json", "gender": ["women"]},
        {"value": "https://www.econscious.net/collections/organic-accessories/products.json", "gender": ["women", "men"]},
    ]
