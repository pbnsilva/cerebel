from .generic import ShopifySpider


class IvanaHelsinkiSpider(ShopifySpider):
    name = "Ivana Helsinki"
    currency = 'EUR'
    max_pages = 5
    collection_urls = [
        {"value": "https://shop.ivanahelsinki.com/collections/dresses/products.json", "gender": ["women"]},
        {"value": "https://shop.ivanahelsinki.com/collections/purses/products.json", "gender": ["women"]},
        {"value": "https://shop.ivanahelsinki.com/collections/top/products.json", "gender": ["women"]},
        {"value": "https://shop.ivanahelsinki.com/collections/bottoms/products.json", "gender": ["women"]},
    ]
