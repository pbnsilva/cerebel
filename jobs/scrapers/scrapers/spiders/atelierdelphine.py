from .generic import ShopifySpider


class AtelierDelphineSpider(ShopifySpider):
    name = "Atelier Delphine"
    allowed_domains = ["atelierdelphine.com"]
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {'value': 'https://atelierdelphine.com/collections/all/products.json', 'gender': ['women']},
    ]
