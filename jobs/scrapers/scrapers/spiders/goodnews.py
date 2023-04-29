from .generic import ShopifySpider


class GoodnewsSpider(ShopifySpider):
    name = 'GoodNews'
    currency = 'EUR'
    max_pages = 10
    collection_urls = [{"value": "https://goodnews.london/collections/all/products.json", "gender": ["men", "women"]}]

    def filter_tags(self, tags):
        return tags + ['sneakers']
