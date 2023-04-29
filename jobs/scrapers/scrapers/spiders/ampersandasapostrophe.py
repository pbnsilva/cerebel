from .generic import ShopifySpider


class AmpersandasapostropheSpider(ShopifySpider):
    name = 'Ampersand As Apostrophe'
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {"value": "https://ampersandasapostrophe.com/collections/totes/products.json", "gender": ["women"]},
        {"value": "https://ampersandasapostrophe.com/collections/crossbody/products.json", "gender": ["women"]},
        {"value": "https://ampersandasapostrophe.com/collections/duffle/products.json", "gender": ["women"]},
        {"value": "https://ampersandasapostrophe.com/collections/backpack/products.json", "gender": ["women"]},
        {"value": "https://ampersandasapostrophe.com/collections/clutches/products.json", "gender": ["women"]},
        {"value": "https://ampersandasapostrophe.com/collections/wallet/products.json", "gender": ["women"]},
        {"value": "https://ampersandasapostrophe.com/collections/mens/products.json", "gender": ["men"]},
    ]
