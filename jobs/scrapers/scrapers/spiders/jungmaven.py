from .generic import ShopifySpider


class JungMavenSpider(ShopifySpider):
    name = 'Jung Maven'
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {"value": "https://jungmaven.com/collections/hemp-core-tees-tshirt-womens/products.json", "gender": ["women"]},
        {"value": "https://jungmaven.com/collections/hemp-tees-tshirt-shortsleeve-womens/products.json", "gender": ["women"]},
        {"value": "https://jungmaven.com/collections/hemp-tees-longsleeve-women/products.json", "gender": ["women"]},
        {"value": "https://jungmaven.com/collections/hemp-tank-top-womens/products.json", "gender": ["women"]},
        {"value": "https://jungmaven.com/collections/hemp-dresses-jumpers/products.json", "gender": ["women"]},
        {"value": "https://jungmaven.com/collections/hemp-core-tees-men/products.json", "gender": ["men"]},
        {"value": "https://jungmaven.com/collections/hemp-tees-long-sleeve-mens/products.json", "gender": ["men"]},
        {"value": "https://jungmaven.com/collections/hemp-shorts-men/products.json", "gender": ["men"]},
    ]
