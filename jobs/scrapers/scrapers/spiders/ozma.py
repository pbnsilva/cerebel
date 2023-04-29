from .generic import ShopifySpider
from bs4 import BeautifulSoup


class OzmaSpider(ShopifySpider):
    name = "Ozma"
    allowed_domains = ["ozmaofcalifornia.com"]
    currency = 'USD'
    max_pages = 20
    collection_urls = [
        {'value': 'https://ozmaofcalifornia.com/collections/all/products.json', 'gender': ['women']},
    ]

    def extract_name(self, name):
        return name.split('|')[0].strip()

    def extract_description(self, body):
        text = BeautifulSoup(body, 'lxml').text.strip()
        if '-->' in text:
            return text.split('-->')[1]
        return text
