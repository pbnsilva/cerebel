from .generic import ShopifySpider


class AllbirdsSpider(ShopifySpider):
    name = 'Allbirds'
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {"value": "https://www.allbirds.com/collections/mens/products.json", "gender": ["men"]},
        {"value": "https://www.allbirds.com/collections/womens/products.json", "gender": ["women"]},
    ]

    def filter_tags(self, tags):
        return tags + ['shoes']
