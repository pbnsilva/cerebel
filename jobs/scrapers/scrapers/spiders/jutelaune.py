from .generic import SquarespaceSpider


class JutelauneSpider(SquarespaceSpider):
    name = 'JUTELAUNE'
    max_pages = 10
    collection_urls = [
        {"value": "http://www.jutelaune.com/shopavarcas/?format=json", "gender": ["women"]},
        {"value": "http://www.jutelaune.com/espadrilles/?format=json", "gender": ["women"]},
    ]
