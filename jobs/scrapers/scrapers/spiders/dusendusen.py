from .generic import ShopifySpider


class DusenDusenSpider(ShopifySpider):
    name = 'Dusen Dusen'
    currency = 'USD'
    max_pages = 10
    collection_urls = [{"value": "https://www.dusendusen.com/collections/womens/products.json", "gender": ["women"]}]
