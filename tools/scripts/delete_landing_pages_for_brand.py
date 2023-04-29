import sys
from google.cloud import storage
from slugify import slugify

if len(sys.argv) < 2:
    print('Usage: python delete_landing_pages_for_brand.py [brand_name]')
    sys.exit(1)

brand = sys.argv[1]
brand_slug = slugify(brand)

storage_client = storage.Client()
bucket = storage_client.get_bucket('assets.cerebel.io')
blobs = bucket.list_blobs(prefix='product_landing_pages')
for blob in blobs:
    bname = blob.name.split('/')[-1]
    if brand_slug in bname:
        blob.delete()
        print('Deleted ' + bname)
