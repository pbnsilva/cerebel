from .generic import ShopifySpider


class LinenFoxClothesSpider(ShopifySpider):
    name = 'Linenfox'
    currency = 'EUR'
    max_pages = 10
    collection_urls = [{"value": "https://linenfoxclothes.com/collections/all/products.json", "gender": ["women"]}]

    def filter_product(self, product):
        name = product['name'].lower()
        if 'towel' in name or 'fabric scraps' in name or 'pillow cases' in name or 'candle' in name or 'fabric samples' in name:
            return False
        return True

    def filter_tags(self, tags):
        return []
