from .generic import ShopifySpider


class DelikateRayneSpider(ShopifySpider):
    name = "DELIKATE RAYNE"
    currency = 'USD'
    max_pages = 5
    allowed_domains = ["www.delikaterayne.com"]
    collection_urls = [
        {'value': 'https://delikaterayne.com/collections/shop-all/products.json', 'gender': ['women']},
    ]
