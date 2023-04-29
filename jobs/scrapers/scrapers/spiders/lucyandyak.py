from .generic import ShopifySpider


class LucyAndYakSpider(ShopifySpider):
    name = "Lucy & Yak"
    allowed_domains = ["lucyandyak.com"]
    max_pages = 5
    currency = 'GBP'
    collection_urls = [
        {'value': 'https://lucyandyak.com/collections/new-in/products.json', 'gender': ['women']},
        {'value': 'https://lucyandyak.com/collections/dungarees/products.json', 'gender': ['women']},
        {'value': 'https://lucyandyak.com/collections/boilersuits/products.json', 'gender': ['women']},
        {'value': 'https://lucyandyak.com/collections/organic-1/products.json', 'gender': ['women']},
        {'value': 'https://lucyandyak.com/collections/dunga-shorts/products.json', 'gender': ['women']},
        {'value': 'https://lucyandyak.com/collections/trousers/products.json', 'gender': ['women']},
        {'value': 'https://lucyandyak.com/collections/outerwear/products.json', 'gender': ['women']},
        {'value': 'https://lucyandyak.com/collections/tops/products.json', 'gender': ['women']},
        {'value': 'https://lucyandyak.com/collections/dresses-1/products.json', 'gender': ['women']},
        {'value': 'https://lucyandyak.com/collections/socks/products.json', 'gender': ['women', 'men']},
        {'value': 'https://lucyandyak.com/collections/menswear-lucy-and-yak-dungarees/products.json', 'gender': ['men']},
    ]

    def filter_tags(self, tags):
        if 'jeans' in tags:
            tags.remove('jeans')
        return tags

    def update_product(self, p):
        if 'trousers' in p['name']:
            tags = []
            for t in p['tags']:
                if 'dungaree' in t.lower():
                    continue
                tags.append(t)
            p['tags'] = tags
