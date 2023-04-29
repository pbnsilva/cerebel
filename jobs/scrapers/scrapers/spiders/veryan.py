from .generic import SquarespaceSpider


class VeryanSpider(SquarespaceSpider):
    name = 'Veryan'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.byveryan.co.uk/shop?category=Women&format=json", "gender": ["women"]},
    ]
