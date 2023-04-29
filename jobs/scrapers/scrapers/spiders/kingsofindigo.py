from .generic import ShopifySpider


class KingsOfIndigoSpider(ShopifySpider):
    name = "Kings Of Indigo"
    currency = 'EUR'
    max_pages = 5
    collection_urls = [
        {'value': 'https://www.kingsofindigo.com/collections/mens-jeans/products.json', 'gender': ['men']},
        {'value': 'https://www.kingsofindigo.com/collections/pants-shorts/products.json', 'gender': ['men']},
        {'value': 'https://www.kingsofindigo.com/collections/mens-jackets/products.json', 'gender': ['men']},
        {'value': 'https://www.kingsofindigo.com/collections/mens-knitwear-sweaters-sweatshirts/products.json', 'gender': ['men']},
        {'value': 'https://www.kingsofindigo.com/collections/mens-shirts-and-t-shirts/products.json', 'gender': ['men']},
        {'value': 'https://www.kingsofindigo.com/collections/accessories-all-items/products.json', 'gender': ['men']},
        {'value': 'https://www.kingsofindigo.com/collections/women-jeans/products.json', 'gender': ['women']},
        {'value': 'https://www.kingsofindigo.com/collections/pants-shorts-and-jumpsuits/products.json', 'gender': ['women']},
        {'value': 'https://www.kingsofindigo.com/collections/skirts-and-dresses/products.json', 'gender': ['women']},
        {'value': 'https://www.kingsofindigo.com/collections/women-jackets/products.json', 'gender': ['women']},
        {'value': 'https://www.kingsofindigo.com/collections/women-knitwear-sweaters-and-sweatshirts/products.json', 'gender': ['women']},
        {'value': 'https://www.kingsofindigo.com/collections/women-blouses-t-shirts/products.json', 'gender': ['women']},
        {'value': 'https://www.kingsofindigo.com/collections/accessories-all-items/products.json', 'gender': ['women']},
    ]

    def update_product(self, p):
        if 'Mens' in p['tags'] and 'Women' in p['tags']:
            p['gender'] = ['women', 'men']
        elif 'Mens' in p['tags']:
            p['gender'] = ['men']
        elif 'Women' in p['tags']:
            p['gender'] = ['women']
