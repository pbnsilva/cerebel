from .generic import SquarespaceSpider


class DavyJSpider(SquarespaceSpider):
    name = 'DavyJ'
    collection_urls = [
        {"value": "https://www.davyj.org/shop?format=json", "gender": ["women"]},
    ]
    max_pages = 5
