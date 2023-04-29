from .generic import ShopifySpider


class UnitedByBlueSpider(ShopifySpider):
    name = "United By Blue"
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {'value': 'https://unitedbyblue.com/collections/gloves-mittens/products.json', 'gender': ['women', 'men']},
        {'value': 'https://unitedbyblue.com/collections/womens-belts-wallets/products.json', 'gender': ['women']},
        {'value': 'https://unitedbyblue.com/collections/bags/products.json', 'gender': ['women', 'men']},
        {'value': 'https://unitedbyblue.com/collections/womens-shorts-1/products.json', 'gender': ['women']},
        {'value': 'https://unitedbyblue.com/collections/womens-pants/products.json', 'gender': ['women']},
        {'value': 'https://unitedbyblue.com/collections/womens-shirts-button-downs/products.json', 'gender': ['women']},
        {'value': 'https://unitedbyblue.com/collections/womens-t-shirts-tanks/products.json', 'gender': ['women']},
        {'value': 'https://unitedbyblue.com/collections/mens-shirts/products.json', 'gender': ['men']},
        {"value": "https://unitedbyblue.com/collections/mens-graphic-t-shirts/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/mens-standards/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/mens-button-downs/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/mens-sweatshirts/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/mens-pants/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/mens-shorts/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/swim/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/mens-vests/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/mens-socks/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/mens-hats/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/mens-jackets-coats/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/mens-shoes/products.json", "gender": ["men"]},
        {"value": "https://unitedbyblue.com/collections/womens-graphic-tees/products.json", "gender": ["women"]},
        {"value": "https://unitedbyblue.com/collections/womens-basics/products.json", "gender": ["women"]},
        {"value": "https://unitedbyblue.com/collections/womens-button-downs/products.json", "gender": ["women"]},
        {"value": "https://unitedbyblue.com/collections/sweaters-sweatshirts/products.json", "gender": ["women"]},
        {"value": "https://unitedbyblue.com/collections/womens-dresses/products.json", "gender": ["women"]},
        {"value": "https://unitedbyblue.com/collections/womens-shorts/products.json", "gender": ["women"]},
        {"value": "https://unitedbyblue.com/collections/womens-swim/products.json", "gender": ["women"]},
        {"value": "https://unitedbyblue.com/collections/womens-socks/products.json", "gender": ["women"]},
        {"value": "https://unitedbyblue.com/collections/womens-lightweight-jackets/products.json", "gender": ["women"]},
        {"value": "https://unitedbyblue.com/collections/womens-hats/products.json", "gender": ["women"]},
        {"value": "https://unitedbyblue.com/collections/womens-shoes/products.json", "gender": ["women"]},
    ]
    _product_names = set()

    def filter_product(self, product):
        if product['name'] in self._product_names:
            return False
        return True
