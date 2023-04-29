from .generic import SquarespaceSpider


class AbacaxiSpider(SquarespaceSpider):
    name = 'Abacaxi'
    max_pages = 1
    collection_urls = [
        {"value": "http://abacaxi-nyc.com/shop/?format=json", "gender": ["women"]},
    ]
