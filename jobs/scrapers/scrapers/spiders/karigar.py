from .generic import ShopifySpider


class KarigarSpider(ShopifySpider):
    name = "Karigar"
    allowed_domains = ["www.karigar.nl"]
    currency = 'EUR'
    max_pages = 20
    collection_urls = [
        {'value': 'https://www.karigar.nl/collections/all/products.json', 'gender': ['women']},
    ]
