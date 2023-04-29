from .generic import SquarespaceSpider


class ToinoabelSpider(SquarespaceSpider):
    name = 'Toino Abel'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.toinoabel.com/shop?format=json", "gender": ["women"]},
    ]

    def update_product(self, p):
        p['tags'] = p.get('tags', []) + ['bags', 'handbags']
