from .generic import SquarespaceSpider


class ZaziSpider(SquarespaceSpider):
    name = 'Zazi'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.zazi-vintage.com/shop/?format=json", "gender": ["women"]},
    ]
