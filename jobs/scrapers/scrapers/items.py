# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import json
from scrapy import Item, Field


class Product(Item):
    id = Field()
    created_at = Field()
    vendor_id = Field()
    name = Field()
    brand = Field()
    brand_id = Field()
    url = Field()
    gender = Field()
    description = Field()
    description_html = Field()
    image_url = Field()
    tags = Field()
    currency = Field()
    price = Field()
    original_price = Field()
    stores = Field()
    variants = Field()
    label_finder_urls = Field()
    share_url = Field()
    _ignore_pipeline = Field(default=False)
    _new_on_sale = Field(default=False)

    def toJSON(self):
        return json.dumps(self, default=lambda o: {k: o.__dict__['_values'][k] for k in o.__dict__['_values'] if not k.startswith('_')}, sort_keys=True)
