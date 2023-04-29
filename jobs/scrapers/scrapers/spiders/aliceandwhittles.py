from .generic import ShopifySpider


class AliceAndWhittlesSpider(ShopifySpider):
    name = 'Alice and Whittles'
    currency = 'USD'
    max_pages = 5
    collection_urls = [
        {"value": "https://www.aliceandwhittles.com/collections/all/products.json", "gender": ["women"]},
    ]
