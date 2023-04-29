from .generic import ShopifySpider


class HareHartSpider(ShopifySpider):
    name = 'Hare+Hart'
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {"value": "https://hareandhart.com/collections/handbags/products.json", "gender": ["women"]},
        {"value": "https://hareandhart.com/collections/totes/products.json", "gender": ["women"]},
        {"value": "https://hareandhart.com/collections/backpacks/products.json", "gender": ["women"]},
        {"value": "https://hareandhart.com/collections/pouches/products.json", "gender": ["women"]},
    ]

    def filter_product(self, product):
        if product['name'] == 'Test Item':
            return False
        return True
