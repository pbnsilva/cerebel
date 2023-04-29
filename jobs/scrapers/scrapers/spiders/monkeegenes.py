from .generic import ShopifySpider


class MonkeegenesSpider(ShopifySpider):
    name = 'monkeegenes'
    currency = 'GBP'
    max_pages = 20
    collection_urls = [
        {'value': 'https://monkeegenes.com/collections/mens/products.json', 'gender': ['men']},
        {'value': 'https://monkeegenes.com/collections/womens/products.json', 'gender': ['women']},
        {'value': 'https://monkeegenes.com/collections/mens-outlet/products.json', 'gender': ['men']},
		{'value': 'https://monkeegenes.com/collections/womens-outlet/products.json', 'gender': ['women']},
    ]
