from .generic import ShopifySpider, HTMLUtil


class LepirolSpider(ShopifySpider):
    name = "Le Pirol"
    allowed_domains = ["lepirol.com"]
    currency = 'DKK'
    max_pages = 20
    collection_urls = [
        {'value': 'https://lepirol.com/collections/shop-all-womens/products.json', 'gender': ['women']},
        {'value': 'https://lepirol.com/collections/shop-all-mens/products.json', 'gender': ['men']},
        {'value': 'https://lepirol.com/collections/accessories/products.json', 'gender': ['women', 'men']},
    ]

    def extract_description(self, body_html):
        start = body_html.index('<p><strong>ENG</strong></p>')
        end = body_html.index('<p><strong>DE</strong></p>')
        return HTMLUtil.to_formatted_text(body_html[start+28:end])

    def filter_tags(self, tags):
        if 'dress' in tags:
            tags.remove('dress')
        return tags
