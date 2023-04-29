from .generic import ShopifySpider


class TwothirdsSpider(ShopifySpider):
    name = 'TwoThirds'
    currency = 'EUR'
    max_pages = 10
    collection_urls = [
        {'value': 'https://twothirds.com/collections/men/products.json', 'gender': ['men']},
        {'value': 'https://twothirds.com/collections/women/products.json', 'gender': ['women']},
        {'value': 'https://twothirds.com/collections/accessories/products.json', 'gender': ['women', 'men']}
    ]
    label_finder_urls = ["https://www.thelabelfinder.com/berlin/twothirds/shops/DE/2271625/2950159"]
