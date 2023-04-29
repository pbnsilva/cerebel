from .generic import ShopifySpider


class AishSpider(ShopifySpider):
    name = "Aish"
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {"value": "https://aishlife.com/collections/clothing/products.json", "gender": ["women"]},
    ]
