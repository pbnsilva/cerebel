from .generic import ShopifySpider


class MatriarchSpider(ShopifySpider):
    name = 'Matriarch'
    currency = 'EUR'
    max_pages = 10
    collection_urls = [{"value": "https://wethematriarch.com/collections/all/products.json", "gender": ["men", "women"]}]

    def filter_images(self, urls):
        # ignore first image
        return urls[1:]
