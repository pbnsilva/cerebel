from .generic import SquarespaceSpider


class DiarteSpider(SquarespaceSpider):
    name = 'diarte'
    collection_urls = [{"value": "https://www.diarte.net/shop/?format=json", "gender": ["women"]}]
    max_pages = 10
