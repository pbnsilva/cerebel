from .generic import SquarespaceSpider


class KamperettSpider(SquarespaceSpider):
    name = 'Kamperett'
    max_pages = 10
    collection_urls = [{"value": "https://www.kamperett.com/shop/?format=json", "gender": ["women"]}]

    def extract_name(self, name):
        return name.split('|')[0].strip()
