from .generic import ShopifySpider


class FarmtofeetSpider(ShopifySpider):
    name = 'Farm to Feet'
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.farmtofeet.com/collections/men-hike/products.json", "gender": ["men"]},
        {"value": "https://www.farmtofeet.com/collections/men-everyday/products.json", "gender": ["men"]},
        {"value": "https://www.farmtofeet.com/collections/men-snow-sports/products.json", "gender": ["men"]},
        {"value": "https://www.farmtofeet.com/collections/men-sport/products.json", "gender": ["men"]},
        {"value": "https://www.farmtofeet.com/collections/men-hunt-fish/products.json", "gender": ["men"]},
        {"value": "https://www.farmtofeet.com/collections/tactical/products.json", "gender": ["men"]},
        {"value": "https://www.farmtofeet.com/collections/women-hike/products.json", "gender": ["women"]},
        {"value": "https://www.farmtofeet.com/collections/women-everyday/products.json", "gender": ["women"]},
        {"value": "https://www.farmtofeet.com/collections/women-snow-sports/products.json", "gender": ["women"]},
        {"value": "https://www.farmtofeet.com/collections/women-sport/products.json", "gender": ["women"]},
        {"value": "https://www.farmtofeet.com/collections/women-hunt-fish/products.json", "gender": ["women"]},
        {"value": "https://www.farmtofeet.com/collections/tactical/products.json", "gender": ["women"]},
    ]
