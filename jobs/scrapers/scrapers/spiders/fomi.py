from .generic import SquarespaceSpider


class FomiSpider(SquarespaceSpider):
    name = 'Fomi'
    collection_urls = [{"value": "http://www.fomicollection.com/shop/?format=json", "gender": ["men", "women"]}]
    max_pages = 10
