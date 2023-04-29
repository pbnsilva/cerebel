from .generic import SquarespaceSpider


class AitchAitchSpider(SquarespaceSpider):
    name = 'Aitch Aitch'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.aitch-aitch.com/shop?format=json", "gender": ["women"]},
    ]
