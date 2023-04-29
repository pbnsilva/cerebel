from .generic import ShopifySpider


class PinkcityprintsSpider(ShopifySpider):
    name = 'Pink City Prints'
    currency = 'GBP'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.pinkcityprints.com/collections/nightwear/products.json", "gender": ["women"]},
        {"value": "https://www.pinkcityprints.com/collections/bags-clutches-and-purses/products.json", "gender": ["women", "men"]},
        {'value': 'https://www.pinkcityprints.com/collections/love/products.json', 'gender': ['women']},
        {"value": "https://www.pinkcityprints.com/collections/clothes/products.json", "gender": ["women"]},
        {'value': 'https://www.pinkcityprints.com/collections/palm-tree-print/products.json', 'gender': ['women']},
        {'value': 'https://www.pinkcityprints.com/collections/hand-embroidery/products.json', 'gender': ['women']},
        {'value': 'https://www.pinkcityprints.com/collections/love/products.json', 'gender': ['women']},
        {'value': 'https://www.pinkcityprints.com/collections/shop-autumn-winter-18/products.json', 'gender': ['women']},
    ]
