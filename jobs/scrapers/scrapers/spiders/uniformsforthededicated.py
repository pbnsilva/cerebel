from .generic import ShopifySpider


class UniformsforthededicatedSpider(ShopifySpider):
    name = 'Uniforms For The Dedicated'
    currency = 'EUR'
    max_pages = 10
    collection_urls = [
        {"value": "https://uniformsforthededicated.com/collections/all/products.json", "gender": ["men"]},
    ]
    label_finder_urls = ["https://www.thelabelfinder.com/berlin/uniforms-for-the-dedicated/shops/DE/455192/2950159"]
