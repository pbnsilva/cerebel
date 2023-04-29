from .generic import ShopifySpider


class IlanaKohnSpider(ShopifySpider):
    name = 'Ilana Kohn'
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {"value": "https://ilanakohn.com/collections/dresses/products.json", "gender": ["women"]},
        {"value": "https://ilanakohn.com/collections/pants/products.json", "gender": ["women"]},
        {"value": "https://ilanakohn.com/collections/jumpsuits/products.json", "gender": ["women"]},
        {"value": "https://ilanakohn.com/collections/shirts/products.json", "gender": ["women"]},
        {"value": "https://ilanakohn.com/collections/jackets/products.json", "gender": ["women"]},
    ]
