from .generic import SquarespaceSpider


class CarlaColourSpider(SquarespaceSpider):
    name = 'Carla Colour'
    max_pages = 10
    collection_urls = [
        {"value": "http://www.carlacolour.com/shop/?format=json", "gender": ["women", "men"]},
    ]

    def update_product(self, p):
        p['tags'] = p.get('tags', []) + ['sunglasses']
