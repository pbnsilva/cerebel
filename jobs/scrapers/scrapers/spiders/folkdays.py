from .generic import ShopifySpider


class FolkDaysSpider(ShopifySpider):
    name = "Folk Days"
    allowed_domains = ["folkdays.com"]
    currency = 'EUR'
    max_pages = 2
    collection_urls = [
        {'value': 'https://folkdays.com/collections/garments/products.json', 'gender': ['women']},
        {'value': 'https://folkdays.com/collections/accessories/products.json', 'gender': ['women']},
        {'value': 'https://folkdays.com/collections/jewellery/products.json', 'gender': ['women']},
    ]

    def extract_name(self, title):
        return title.split('<br/>')[0]

    def filter_product(self, product):
        if 'gift card' in product['name'].lower():
            return False
        return True
