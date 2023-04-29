from .generic import ShopifySpider


class HundHundSpider(ShopifySpider):
    name = 'Hund Hund'
    currency = 'EUR'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.hundhund.com/collections/woman/products.json", "gender": ["women"]},
        {"value": "https://www.hundhund.com/collections/man/products.json", "gender": ["men"]},
    ]

    def filter_tags(self, tags):
        return []
