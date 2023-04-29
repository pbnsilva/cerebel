from .generic import SquarespaceSpider


class MiakodaSpider(SquarespaceSpider):
    name = 'Miakoda'
    max_pages = 10
    collection_urls = [{"value": "https://www.miakodanewyork.com/shop?format=json", "gender": ["women"]}]
