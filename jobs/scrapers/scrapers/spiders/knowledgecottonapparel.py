from .generic import ShopifySpider


class KnowledgecottonapparelSpider(ShopifySpider):
    name = 'Knowledge Cotton Apparel'
    currency = 'EUR'
    allowed_domains = ['knowledgecottonapparel.com']
    max_pages = 5
    collection_urls = [
        {"value": "https://knowledgecottonapparel.com/collections/t-shirts/products.json", "gender": ["men"]},
        {"value": "https://knowledgecottonapparel.com/collections/polos/products.json", "gender": ["men"]},
        {"value": "https://knowledgecottonapparel.com/collections/shirt/products.json", "gender": ["men"]},
        {"value": "https://knowledgecottonapparel.com/collections/sweats/products.json", "gender": ["men"]},
        {"value": "https://knowledgecottonapparel.com/collections/knits/products.json", "gender": ["men"]},
        {"value": "https://knowledgecottonapparel.com/collections/blazers/products.json", "gender": ["men"]},
        {"value": "https://knowledgecottonapparel.com/collections/jackets/products.json", "gender": ["men"]},
        {"value": "https://knowledgecottonapparel.com/collections/pants/products.json", "gender": ["men"]},
        {"value": "https://knowledgecottonapparel.com/collections/shorts/products.json", "gender": ["men"]},
        {"value": "https://knowledgecottonapparel.com/collections/socks/products.json", "gender": ["men"]},
        {"value": "https://knowledgecottonapparel.com/collections/underwear/products.json", "gender": ["men"]},
        {"value": "https://knowledgecottonapparel.com/collections/hats-scarves/products.json", "gender": ["men"]},
    ]
    label_finder_urls = ["https://www.thelabelfinder.com/berlin/knowledge-cotton-apparel/shops/DE/31627/2950159"]
