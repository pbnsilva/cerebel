import json
import csv
from io import StringIO
import requests
from scrapy import Spider, Request
from scrapers.items import Product


class JJackmanSpider(Spider):
    name = 'j.jackman'
    allowed_domains = ['www.jjackman.com']

    def __init__(self, *a, **kw):
        super(JJackmanSpider, self).__init__(*a, **kw)
        self.feed_url = 'https://www.wix.com/stores/catalog/export/csv/facebook/b4eafeef-6614-4649-8783-845959cccacd'
        self.headers = {'Content-Type': 'application/json',
                        'X-ecom-instance': 'QD1i3_q6I7deNVcQ35vjNnuuXJOOkDcmLOaDxdf1vWo.eyJpbnN0YW5jZUlkIjoiYjRlYWZlZWYtNjYxNC00NjQ5LTg3ODMtODQ1OTU5Y2NjYWNkIiwiYXBwRGVmSWQiOiIxMzgwYjcwMy1jZTgxLWZmMDUtZjExNS0zOTU3MWQ5NGRmY2QiLCJtZXRhU2l0ZUlkIjoiNTRkZmEyMzctZDJlMy00MTk1LWE1NTUtOTI5NzIxYzEyMWU5Iiwic2lnbkRhdGUiOiIyMDE5LTAyLTAxVDE4OjEwOjIxLjc4OFoiLCJ1aWQiOm51bGwsImlwQW5kUG9ydCI6Ijk0LjE2Ljc1LjgxLzM1NDIwIiwidmVuZG9yUHJvZHVjdElkIjoiUHJlbWl1bTEiLCJkZW1vTW9kZSI6ZmFsc2UsIm9yaWdpbkluc3RhbmNlSWQiOiI3ZmE0NzRmOS1iYjI4LTQ4OGYtYTI1Yy1hOWM3MDg2YWVhY2YiLCJhaWQiOiI2OGNlZGVjMS02NGQ1LTRkZTgtYWU2My1hZmVjNWY3OGJkYmEiLCJiaVRva2VuIjoiZTAzNTVjZDgtYjRmNy0wN2RjLTIyZDYtMTZjZTc4MGRlYjI0Iiwic2l0ZU93bmVySWQiOiJmYWFmYzk2YS1mOTUyLTQ2ZWMtYTMxMi01YWU2MGVjNDFlMGMifQ',
                        'Authorization': 'QD1i3_q6I7deNVcQ35vjNnuuXJOOkDcmLOaDxdf1vWo.eyJpbnN0YW5jZUlkIjoiYjRlYWZlZWYtNjYxNC00NjQ5LTg3ODMtODQ1OTU5Y2NjYWNkIiwiYXBwRGVmSWQiOiIxMzgwYjcwMy1jZTgxLWZmMDUtZjExNS0zOTU3MWQ5NGRmY2QiLCJtZXRhU2l0ZUlkIjoiNTRkZmEyMzctZDJlMy00MTk1LWE1NTUtOTI5NzIxYzEyMWU5Iiwic2lnbkRhdGUiOiIyMDE5LTAyLTAxVDE4OjEwOjIxLjc4OFoiLCJ1aWQiOm51bGwsImlwQW5kUG9ydCI6Ijk0LjE2Ljc1LjgxLzM1NDIwIiwidmVuZG9yUHJvZHVjdElkIjoiUHJlbWl1bTEiLCJkZW1vTW9kZSI6ZmFsc2UsIm9yaWdpbkluc3RhbmNlSWQiOiI3ZmE0NzRmOS1iYjI4LTQ4OGYtYTI1Yy1hOWM3MDg2YWVhY2YiLCJhaWQiOiI2OGNlZGVjMS02NGQ1LTRkZTgtYWU2My1hZmVjNWY3OGJkYmEiLCJiaVRva2VuIjoiZTAzNTVjZDgtYjRmNy0wN2RjLTIyZDYtMTZjZTc4MGRlYjI0Iiwic2l0ZU93bmVySWQiOiJmYWFmYzk2YS1mOTUyLTQ2ZWMtYTMxMi01YWU2MGVjNDFlMGMifQ'}

    def start_requests(self):
        req = requests.get(self.feed_url)
        f = StringIO(req.text)
        next(f)
        reader = csv.reader(f, delimiter=',')
        for r in reader:
            yield Request(r[3], callback=self.parse_product_page, meta={'brand': self.name, 'gender': ['women']})

    def parse_product_page(self, response):
        slug = response.url.split('/')[-1]
        req = requests.post('https://www.jjackman.com/_api/wix-ecommerce-storefront-web/api', data=json.dumps(self._get_product_request_payload(slug)), headers=self.headers)
        if req.status_code != 200:
            return
        data = req.json()['data']['catalog']['product']
        if not data['isInStock']:
            return
        p = Product()
        p['name'] = data['name']
        p['url'] = response.url
        p['description'] = data['additionalInfo'][0]['description']
        p['image_url'] = ['https://static.wixstatic.com/media/' + v['url'] for v in data['media']]
        if data['comparePrice'] != 0:
            p['price'] = data['comparePrice']
            p['original_price'] = data['price']
        else:
            p['price'] = data['price']
        p['currency'] = 'eur'
        p['brand'] = response.meta['brand']
        p['gender'] = response.meta['gender']
        yield p

    def _get_product_request_payload(self, slug):
        return {"query": "query productBySlug($externalId: String!, $slug: String!) {\n  appSettings(externalId: $externalId) {\n    widgetSettings\n  }\n  catalog{\n    product(slug: $slug) {\n      id\n      description\n      isVisible\n      sku\n      ribbon\n      price\n      comparePrice\n      formattedPrice\n      formattedComparePrice\n      seoTitle\n      seoDescription\n      digitalProductFileItems{\n        fileId\n        fileType\n        fileName\n      }\n      productItems {\n        price\n        comparePrice\n        formattedPrice\n        formattedComparePrice\n        optionsSelections\n        isVisible\n        inventory {\n          status\n          quantity\n        }\n        sku\n        weight\n        surcharge\n      }\n      name\n      isTrackingInventory\n      inventory {\n        status\n        quantity\n      }\n      isVisible\n      isManageProductItems\n      isInStock\n      media {\n        url\n        mediaType\n        videoFiles {\n          url\n          width\n          height\n          format\n          quality\n        }\n        width\n        height\n        index\n        title\n      }\n      customTextFields {\n        title\n        isMandatory\n        inputLimit\n      }\n      nextOptionsSelectionId\n      options {\n        title\n        optionType\n        selections {\n          id\n          value\n          description\n          linkedMediaItems {\n            url\n            mediaType\n            width\n            height\n            index\n            title\n          }\n        }\n      }\n      productType\n      urlPart\n      additionalInfo {\n        id\n        title\n        description\n        index\n      }\n    }\n  }\n}",
                "variables": {"slug": slug, "externalId": ""},
                "source": "WixStoresWebClient",
                "operationName": "getProductBySlug"}
