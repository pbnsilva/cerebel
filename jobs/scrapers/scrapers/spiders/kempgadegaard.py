from .generic import SquarespaceSpider


class KempgadegaardSpider(SquarespaceSpider):
    name = 'Kemp Gadegaard'
    max_pages = 10
    collection_urls = [
        {'value': 'https://www.kempgadegaard.com/autumn-winter-18/?format=json', 'gender': ['women']},
        {'value': 'https://www.kempgadegaard.com/accessories/?format=json', 'gender': ['women']},
        {"value": "https://www.kempgadegaard.com/springsummer18?format=json", "gender": ["women"]},
        {"value": "https://www.kempgadegaard.com/last-chance-sale?format=json", "gender": ["women"]},
    ]
