from .generic import ShopifySpider


class KayuBelleSpider(ShopifySpider):
    name = 'Kayu'
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {"value": "https://shop.kayudesign.com/collections/all/products.json", "gender": ["women"]},
    ]
