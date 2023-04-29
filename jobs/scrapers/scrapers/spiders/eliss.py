from .generic import SquarespaceSpider


class EllissSpider(SquarespaceSpider):
    name = 'Elliss'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.elliss.co.uk/shop/?format=json", "gender": ["women"]},
    ]
