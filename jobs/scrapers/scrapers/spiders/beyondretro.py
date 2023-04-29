from .generic import ShopifySpider


class BeyondRetroSpider(ShopifySpider):
    name = "Beyond Retro"
    currency = 'GBP'
    max_pages = 20
    collection_urls = [
        {'value': 'https://www.beyondretro.com/collections/women-tops/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-christmas-jumpers/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-coats/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-dresses/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-vintage-dungarees/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-jackets/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/womens-vintage-jeans/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-knits/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-lingerie/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-playsuit-jumpsuit/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-shorts/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-shoes/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-skirts/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-sweatshirt/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-bodies-swimwear/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-t-shirt/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/women-trousers/products.json', 'gender': ['women']},
        {'value': 'https://www.beyondretro.com/collections/men-christmas-jumpers/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-coats/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-all-in-ones/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-jackets/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-jeans/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-knits/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/mens-vintage-military-army-surplus-camouflage-print/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-shirts/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-shorts/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-mens-vintage-suiting/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-sweatshirt/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-t-shirt/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-t-shirt-polo-t-shirt/products.json', 'gender': ['men']},
        {'value': 'https://www.beyondretro.com/collections/men-trousers/products.json', 'gender': ['men']},
    ]

    def update_product(self, p):
        p['url'] = 'https://www.paidonresults.net/c/52150/1/1818/0/products' + p['url'].split('products')[-1]
        p['tags'] += ['vintage']
