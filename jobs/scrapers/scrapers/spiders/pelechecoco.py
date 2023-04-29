from .generic import ShopifySpider


class PelechecocoSpider(ShopifySpider):
    name = "Pelechecoco"
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {"value": "https://pelechecoco.com/collections/women/products.json", "gender": ["women"]},
        {"value": "https://pelechecoco.com/collections/men/products.json", "gender": ["men"]},
    ]

    def update_product(self, product):
        desc = product['description'].lower().split()
        if 'leather' in desc:
            product['tags'] += ['leather']
        if 'jacket' in desc:
            product['tags'] += ['jacket']
