from .generic import ShopifySpider


class MayamikoSpider(ShopifySpider):
    name = 'Mayamiko'
    currency = 'GBP'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.mayamiko.com/collections/dresses/products.json", "gender": ["women"]},
        {"value": "https://www.mayamiko.com/collections/jackets/products.json", "gender": ["women"]},
        {"value": "https://www.mayamiko.com/collections/trousers/products.json", "gender": ["women"]},
        {"value": "https://www.mayamiko.com/collections/exclusive-prints-tops-and-tees/products.json", "gender": ["women"]},
        {"value": "https://www.mayamiko.com/collections/shorts/products.json", "gender": ["women"]},
        {"value": "https://www.mayamiko.com/collections/skirts/products.json", "gender": ["women"]},
    ]

    def filter_tags(self, tags):
        # ignore tags, Mayamiko adds wrong tags
        return []
