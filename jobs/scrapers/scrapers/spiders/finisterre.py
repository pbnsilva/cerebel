from .generic import ShopifySpider


class FinisterreSpider(ShopifySpider):
    name = 'Finisterre'
    currency = 'GBP'
    max_pages = 10
    collection_urls = [
        {"value": "https://finisterre.com/collections/womens-outerwear/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-knitwear/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-denim/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-trousers-shorts/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-dresses-skirts/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-sweats-hoodies/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-tees-tops/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-merino-wool-base-layers/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-underwear/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-swimwear/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-hats-beanies/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/belts-accessories/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-socks/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-bags/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/womens-footwear/products.json", "gender": ["women"]},
        {"value": "https://finisterre.com/collections/mens-outerwear/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/mens-knitwear/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/mens-denim/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/mens-trousers-and-jeans/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/mens-sweats-and-hoodies/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/mens-shirts-polos/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/mens-t-shirts/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/mens-merino-wool-base-layers/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/mens-underwear/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/mens-wetsuits-swimwear/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/hats-beanies/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/belts-accessories/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/socks/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/womens-bags/products.json", "gender": ["men"]},
        {"value": "https://finisterre.com/collections/mens-footwear/products.json", "gender": ["men"]},
    ]
