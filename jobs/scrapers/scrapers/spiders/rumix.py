from .generic import ShopifySpider


class RumixSpider(ShopifySpider):
    name = 'Rumix'
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {"value": "https://rumixfeelgood.com/collections/tops/products.json", "gender": ["women"]},
        {"value": "https://rumixfeelgood.com/collections/sport-bras-tops/products.json", "gender": ["women"]},
        {"value": "https://rumixfeelgood.com/collections/leggings/products.json", "gender": ["women"]},
        {"value": "https://rumixfeelgood.com/collections/shorts/products.json", "gender": ["women"]},
        {"value": "https://rumixfeelgood.com/collections/capris/products.json", "gender": ["women"]},
        {"value": "https://rumixfeelgood.com/collections/pouch-bags/products.json", "gender": ["women"]},
    ]
