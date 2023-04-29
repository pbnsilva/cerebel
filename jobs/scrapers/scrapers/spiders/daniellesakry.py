from .generic import SquarespaceSpider


class DanielleSakrySpider(SquarespaceSpider):
    name = 'Danielle Sakry'
    collection_urls = [
        {"value": "http://daniellesakry.com/shop/?format=json", "gender": ["women"]},
    ]
    max_pages = 5
