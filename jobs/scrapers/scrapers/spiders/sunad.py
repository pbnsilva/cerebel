from .generic import SquarespaceSpider


class SunadSpider(SquarespaceSpider):
    name = 'Sunad'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.sunad.es/en/shop/?format=json", "gender": ["women"]},
    ]

    def filter_tags(self, tags):
        return tags
