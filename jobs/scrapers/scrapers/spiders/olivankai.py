from .generic import ShopifySpider


class OlivanKaiSpider(ShopifySpider):
    name = 'Olivan Kai'
    currency = 'EUR'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.olivankai.com/collections/all/products.json", "gender": ["women"]},
    ]
