from. generic import ShopifySpider


class BatokoSpider(ShopifySpider):
    name = 'Batoko'
    currency = 'GBP'
    max_pages = 5
    collection_urls = [{"value": "https://www.batoko.com/collections/swimsuits/products.json", "gender": ["women"]}]

    def filter_tags(self, tags):
        return tags + ['swimsuits']
