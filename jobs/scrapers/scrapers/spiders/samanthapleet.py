from .generic import ShopifySpider


class SamanthapleetSpider(ShopifySpider):
    name = 'Samantha Pleet'
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {"value": "https://samanthapleet.com/collections/all/products.json", "gender": ["women"]},
    ]
