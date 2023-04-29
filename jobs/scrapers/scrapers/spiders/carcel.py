from .generic import ShopifySpider


class CarcelSpider(ShopifySpider):
    name = 'Carcel'
    currency = 'EUR'
    max_pages = 20
    collection_urls = [
        {"value": "https://carcel.co/collections/all/products.json", "gender": ["women"]},
    ]
