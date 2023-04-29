## Faer scrapers

This directory contains all the spiders for the brands, and all the configurations needed to deploy them.  

We use scrapy to handle the crawling. A job is executed periodically that triggers the crawling on the `scrapyd` server running on the cluster. You can monitor the spiders and jobs that are currently deployed by checkind the scrapers app on the dashboard [here](https://www.cerebel.io/dashboard/scrapers).

## Data Quality

High quality product data in Faer is crucial to a good user experience. Data for a product must include:

* Brand
* Title
* Description
* Gender: Men, women or both for unisex products
* Images: At least one, but not more than five high resolution product images
* Price: Including its currency and if available discounted price

**Textual data**, e.g. title, description, must be free of html entities or other formatting information except for line breaks. The data must be capitalized normally, e.g. not in all caps.

In terms of semantics, textual data must only cover the actual information, e.g. a title must not include the brand name or other information added for SEO purposes. Typically such other information is separated with `|` or `*` in the data. Descriptions should be human-readable and ideally make for one coherent text.

All textual data must be in English language, use Google Translate during import if needed.

**Visual data**, e.g. images, must have a min 1136 x 640 pixel resolution and be in portrait mode. Images must be sharp and "look good", think fashion magazine quality. Ideally the product images include both product shots, i.e. only the product on a plain background, and look shots, i.e. the product in real-life on a person. If a product has a square aspect ratio, it should be transformed to fit the portrait mode of Faer. Important product details, such as the sleeves on a (t)shirt must be retained when the image is transformed.


## Creating Spiders

### Setup
You need to have `scrapy` and `scrapyd-client` installed:  
```
pip install scrapy
pip install git+https://github.com/scrapy/scrapyd-client
```

### Create a spider
Spiders go under the `scrapers/spiders/` directory. The name of the file should be the name of the brand, in lower case, and without any special characters. See one of the many other spiders for examples.

### Test
You can test run your spider by running:  
```
scrapy crawl MySpider -o myspider.jl
```
This will run the spider, and dump the extracted products to `myspider.jl`.

### Deploy the spider
To deploy the spider, you must port-forward to the `scrapyd` server first:
```
kubectl port-forward $(kubectl get pod | grep scrapyd | tr -s ' ' | cut -d ' ' -f 1) 6800:6800
```
Then, run:
```
make deploy-spiders
```
This will create an `egg` package and push it to the server.  

Confirm that your spider was deployed by checking the [dashboard](https://www.cerebel.io/dashboard/scrapers).

### Deploy the cronjob
If you made any changes to the cronjob configuration, deploy them with:
```
make deploy-cronjob
```

## Pipelines
Once a product is scraped is goes through a pipeline, where a number of things are done.  
The pipelines are defined [here](https://github.com/petard/cerebel/blob/master/jobs/scrapers/scrapers/pipelines.py).  
And you can enable them [here](https://github.com/petard/cerebel/blob/master/jobs/scrapers/scrapers/settings.py#L72).  
