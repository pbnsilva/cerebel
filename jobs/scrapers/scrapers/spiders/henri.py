from .generic import ShopifySpider


class HenriSpider(ShopifySpider):
    name = 'Henri'
    collection_urls = [{"value": "https://henri.london/collections/shop-the-store/products.json", "gender": ["women"]}]
    currency = 'GBP'
    max_pages = 10

    def filter_tags(self, tags):
        return []
