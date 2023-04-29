from .generic import ShopifySpider


class RotholzSpider(ShopifySpider):
    name = "Rotholz"
    currency = 'EUR'
    max_pages = 10
    translate_to = 'en'
    collection_urls = [
        {"value": "https://rotholz-store.com/collections/maenner-t-shirts/products.json", "gender": ["men"]},
        {"value": "https://rotholz-store.com/collections/maenner-hemden/products.json", "gender": ["men"]},
        {"value": "https://rotholz-store.com/collections/maenner-longsleeves/products.json", "gender": ["men"]},
        {"value": "https://rotholz-store.com/collections/maenner-sweatshirts/products.json", "gender": ["men"]},
        {"value": "https://rotholz-store.com/collections/maenner-hoodies/products.json", "gender": ["men"]},
        {"value": "https://rotholz-store.com/collections/maenner-jacken/products.json", "gender": ["men"]},
        {"value": "https://rotholz-store.com/collections/maenner-strick-pullover-merino/products.json", "gender": ["men"]},
        {"value": "https://rotholz-store.com/collections/maenner-hosen/products.json", "gender": ["men"]},
        {"value": "https://rotholz-store.com/collections/frauen-t-shirts/products.json", "gender": ["women"]},
        {"value": "https://rotholz-store.com/collections/frauen-blusen/products.json", "gender": ["women"]},
        {"value": "https://rotholz-store.com/collections/frauen-longsleeves/products.json", "gender": ["women"]},
        {"value": "https://rotholz-store.com/collections/frauen-sweatshirts/products.json", "gender": ["women"]},
        {"value": "https://rotholz-store.com/collections/frauen-hoodies/products.json", "gender": ["women"]},
        {"value": "https://rotholz-store.com/collections/frauen-jacken/products.json", "gender": ["women"]},
        {"value": "https://rotholz-store.com/collections/frauen-strick/products.json", "gender": ["women"]},
        {"value": "https://rotholz-store.com/collections/frauen-hosen/products.json", "gender": ["women"]},
    ]
