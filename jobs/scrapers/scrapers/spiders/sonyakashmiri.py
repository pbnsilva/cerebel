from .generic import ShopifySpider


class SonyakashmiriSpider(ShopifySpider):
    name = 'Sonya Kashmiri'
    currency = 'GBP'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.sonyakashmiri.com/collections/frontpage/products.json", "gender": ["women"]},
        {"value": "https://www.sonyakashmiri.com/collections/crossbody-bags/products.json", "gender": ["women"]},
        {"value": "https://www.sonyakashmiri.com/collections/purses-1/products.json", "gender": ["women"]},
    ]
