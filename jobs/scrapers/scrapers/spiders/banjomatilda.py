from .generic import ShopifySpider


class BanjoAndMatildaSpider(ShopifySpider):
    name = "Banjo & Matilda"
    allowed_domains = ["www.banjoandmatilda.com"]
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {'value': 'https://www.banjoandmatilda.com/collections/shop-all/products.json', 'gender': ['women']},
    ]
