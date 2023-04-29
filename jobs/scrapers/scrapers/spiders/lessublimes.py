from .generic import ShopifySpider


class LessublimesSpider(ShopifySpider):
    name = 'Les Sublimes'
    currency = 'EUR'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.les-sublimes.com/collections/tops/products.json", "gender": ["women"]},
        {"value": "https://www.les-sublimes.com/collections/shirts-blouses/products.json", "gender": ["women"]},
        {"value": "https://www.les-sublimes.com/collections/dresses/products.json", "gender": ["women"]},
        {"value": "https://www.les-sublimes.com/collections/skirts/products.json", "gender": ["women"]},
        {"value": "https://www.les-sublimes.com/collections/shoes/products.json", "gender": ["women"]},
        {"value": "https://www.les-sublimes.com/collections/accessories/products.json", "gender": ["women"]},
    ]
