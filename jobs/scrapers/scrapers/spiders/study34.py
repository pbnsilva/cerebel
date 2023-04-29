from .generic import ShopifySpider
from bs4 import BeautifulSoup


class Study34Spider(ShopifySpider):
    name = 'Study34'
    currency = 'GBP'
    max_pages = 10
    collection_urls = [
        {"value": "https://www.study34.co.uk/collections/all/products.json", "gender": ["women"]},
    ]

    def extract_name(self, title):
        return BeautifulSoup(title, 'lxml').text.strip()
