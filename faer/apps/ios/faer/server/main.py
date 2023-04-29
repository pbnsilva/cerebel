# Copyright 2015 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# [START gae_flex_storage_app]
import logging
import os
import requests
import time
import json

from flask import Flask, request
from google.cloud import storage

app = Flask(__name__)

# Configure this environment variable via app.yaml
CLOUD_STORAGE_BUCKET = os.environ['CLOUD_STORAGE_BUCKET']
#helper functions

def prepare(gender):
    freshlooks_data = fresh_looks(gender)

    data = {
        "created_at": int(time.time()),
        'teaser': []
    }
    data["teaser"].append(popular_categories(freshlooks_data))
    data["teaser"].append(brand_spotlight(freshlooks_data, gender))
    return data

def fresh_looks(gender):
    r = requests.get('https://api.cerebel.io/v3/store/faer/feed?token=AonNLZaEXMtLiHdqJqqGQjKrVRGMhq&page=1&size=50&gender='+gender)
    return r.json()

def search_request(query, gender, size):
    payload = {
	    "query": query,
	    "offset": 0,
	    "size": size,
	    "filters": {
		    "gender": gender
	    }
    }
    headers = {
        "X-Cerebel-Token": "AonNLZaEXMtLiHdqJqqGQjKrVRGMhq",
        "Content-Type": "application/json"
    }
    r = requests.post("https://api.cerebel.io/v3/store/faer/search/text", json=payload, headers=headers)
    return r.json()

def upload_data(filename, jsonString):
    print(filename, jsonString)

    gcs = storage.Client()

    # Get the bucket that the file will be uploaded to.
    bucket = gcs.get_bucket(CLOUD_STORAGE_BUCKET)

    # Create a new blob and upload the file's content.
    blob = bucket.blob(filename)

    blob.upload_from_string(
        jsonString,
        content_type='application/json'
    )

    # The public URL can be used to directly access the uploaded file via HTTP.
    return blob.public_url

#teasers
def popular_categories(freshlooks_data):
    teaser_category = {
        "type": "categories",
        "name": "Popular Categories",
        "content": []        
    }
    categories = []
    for record in freshlooks_data["records"]:
        item = record["items"][0]
        image_url = item["image_url"][0]
        annotations = item["annotations"]
        if "category" in annotations:
            category = annotations["category"][0]
            if category not in categories:
                content = {
                    "title": category,
                    "image_url": image_url
                }
                teaser_category["content"].append(content)
                categories.append(category)
    return teaser_category

def brand_spotlight(freshlooks_data, gender):
    teaser_brands = {
        "type": "brands",
        "name": "Brand Spotlight",
        "content": []        
    }
    
    brands = [] #ensure unique brands in spotlight
    for record in freshlooks_data["records"][0:10]:
        item = record["items"][0]
        brand = item["brand"]
        if brand not in brands:
            data = search_request(brand, gender, 10)
            items = data["matches"]["items"]
            totalItems = data["matches"]["total"]
            if totalItems > 0:
                content = {
                    "title": brand,
                    "items": items
                }
                teaser_brands["content"].append(content)
                brands.append(brand)
    return teaser_brands

#api handlers
@app.route('/search_homepage/update/<gender>', methods=['GET'])
def search_homepage_update(gender):

    if not (gender == "women" or gender == "men"):
        return """
        Bad request
        """.format(e), 400

    data = prepare(gender)

    filename = "search_homepage."+gender+".json"

    return upload_data(filename, json.dumps(data))


@app.errorhandler(500)
def server_error(e):
    logging.exception('An error occurred during a request.')
    return """
    An internal error occurred: <pre>{}</pre>
    See logs for full stacktrace.
    """.format(e), 500


if __name__ == '__main__':
    # This is used when running locally. Gunicorn is used to run the
    # application on Google App Engine. See entrypoint in app.yaml.
    app.run(host='127.0.0.1', port=8080, debug=True)
# [END gae_flex_storage_app]