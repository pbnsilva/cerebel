from .generic import ShopifySpider


class EtikoSpider(ShopifySpider):
    name = 'Etiko'
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {"value": "https://etiko.com.au/collections/womens/products.json", "gender": ["women"]},
        {"value": "https://etiko.com.au/collections/mens/products.json", "gender": ["men"]},
    ]
