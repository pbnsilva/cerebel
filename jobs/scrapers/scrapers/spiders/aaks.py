from .generic import SquarespaceSpider


class AaksSpider(SquarespaceSpider):
    name = 'Aaks'
    max_pages = 5
    collection_urls = [
        {'value': 'https://www.aaksonline.com/all?format=json', 'gender': ['women']},
    ]

    def update_product(self, p):
        p['tags'] = ['bags']
