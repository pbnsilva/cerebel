from .generic import SquarespaceSpider


class LessTooLateSpider(SquarespaceSpider):
    name = 'Less Too Late'
    max_pages = 5
    collection_urls = [{"value": "https://www.lesstoolate.com/shop-online/?format=json", "gender": ["men", "women"]}]
