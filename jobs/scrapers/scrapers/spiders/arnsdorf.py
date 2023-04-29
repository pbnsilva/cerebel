from .generic import ShopifySpider


class ArnsdorfSpider(ShopifySpider):
    name = "Arnsdorf"
    allowed_domains = ["arnsdorf.com.au"]
    currency = 'USD'
    max_pages = 10
    collection_urls = [
        {'value': 'https://arnsdorf.com.au/collections/all/products.json', 'gender': ['women']},
    ]

    def filter_product(self, product):
        if product['name'] in {'Gift Voucher'}:
            return False
        if product['name'].startswith('Unconditional Magazine'):
            return False
        return True
