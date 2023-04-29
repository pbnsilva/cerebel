from .generic import SquarespaceSpider


class FoolDostSpider(SquarespaceSpider):
    name = 'Fool Dost'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.fooldost.com/shop/?format=json", "gender": ["women"]},
    ]
