from .generic import ShopifySpider


class DoloresHazeSpider(ShopifySpider):
    name = "Dolores Haze"
    allowed_domains = ["doloreshaze.com"]
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {'value': 'https://doloreshaze.com/collections/all/products.json', 'gender': ['women']},
    ]
