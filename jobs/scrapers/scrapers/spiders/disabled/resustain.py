from .generic import ShopifySpider


class ResustainSpider(ShopifySpider):
    name = 'Resustain'
    currency = 'GBP'
    max_pages = 10
    collection_urls = [
        {"value": "https://resustainclothing.com/collections/mens-tshirts/products.json", "gender": ["men"]},
        {"value": "https://resustainclothing.com/collections/mens-tops-sweatshirts/products.json", "gender": ["men"]},
        {"value": "https://resustainclothing.com/collections/mens-jackets/products.json", "gender": ["men"]},
        {"value": "https://resustainclothing.com/collections/mens-trousers/products.json", "gender": ["men"]},
        {"value": "https://resustainclothing.com/collections/womens-t-shirts/products.json", "gender": ["women"]},
        {"value": "https://resustainclothing.com/collections/womens-tops-sweatshirts/products.json", "gender": ["women"]},
    ]
