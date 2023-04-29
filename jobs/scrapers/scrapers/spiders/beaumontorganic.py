from .generic import ShopifySpider


class BeaumontorganicSpider(ShopifySpider):
    name = 'Beaumont Organic'
    currency = 'GBP'
    max_pages = 15
    collection_urls = [
        {"value": "https://www.beaumontorganic.com/collections/all/products.json", "gender": ["women"]},
    ]
