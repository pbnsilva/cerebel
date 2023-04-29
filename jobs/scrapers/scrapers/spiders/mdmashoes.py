from .generic import ShopifySpider


class MdmashoesSpider(ShopifySpider):
    name = 'MDMAshoes'
    currency = 'EUR'
    max_pages = 10
    collection_urls = [{"value": "https://mdmashoes.com/collections/mdmashoes/products.json", "gender": ["men", "women"]}]
