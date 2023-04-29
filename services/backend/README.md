Exposes the backend APIs.


[Search](#search-service)  
[Feed](#feed-service)  
[Store](#store-service)  
[User](#user-service)  
[Brand](#brand-service)  


# Search service

Exposes the search API, encapsulates general search framework and performs specific queries to downstream stores/indexes.  

See how to run the service [here](cmd/srv).  

See how to run the CLI tool [here](cmd/cli).

[API v3](#api-v3)  
- [Text search](#text-search)
- [Image search](#image-search)
- [Get Item](#get-item)
- [Filtering](#filtering)
- [Sorting](#sorting)
- [Aggregations](#aggregations)
- [Guided search](#guided-search)  
- [Suggest](#suggest)  
- [Teasers](#teasers)  
  
[Product model](#product-model)

---

## API v3

### Text search
```bash
curl --request POST \
  --url https://api.cerebel.io/v3/store/faer/search/text \
  --header 'Content-Type: application/json' \
  --header 'X-Cerebel-Token: myReadToken' \
  --data '{"query": "black dress"}'
```

| Parameter       | Type    | Description |
| --------------- | ------- | ----------- |
| query           | string  | The search query text |
| size            | integer | Maximum number of results to return |
| offset          | integer | Offset from the first result (useful for pagination) |
| filters         | object  | Filter results with specific values |
| fields          | string  | Return only the fields in this array |
| aggregations    | object  | Facet and show doc count for fields. |
| showGuided      | boolean | Whether or not to return guided search (a.k.a. search suggestions) |
| showSimilar     | boolean | Whether or not to return results for a similar query, if the original one returns no results |

Full example:
```json
{
    "query": "dress",
    "size": 20,
    "filters": {"gender": "women"},
    "fields": ["id", "name", "image_url"],
    "showGuided": true
}
```

### Image search
```bash
img=$(base64 my-image.jpg)
json='{
    "image": {
        "content":"'$img'"
    }
}'
echo $json | curl -H "X-Cerebel-Token: myReadToken" -H "Content-Type: application/json" -XPOST 'https://api.cerebel.io/v3/store/faer/search/image' -d @-
```

Alternatively, you can pass an image URL as an _escaped_ string:
```bash
json='{
    "image": {
        "source": "https%3A%2F%2Fmyawesomesite.com%2Fimage.com"
    }
}'
echo $json | curl -H "X-Cerebel-Token: myReadToken" -H "Content-Type: application/json" -XPOST 'https://api.cerebel.io/v3/store/faer/search/image' -d @-
```
If both `content` and `source` are used, then `content` is prioritized and `source` is ignored.


| Parameter       | Type    | Description |
| --------------- | ------- | ----------- |
| image           | object  | Image content or source URL |
| size            | integer | Maximum number of results to return |
| offset          | integer | Offset from the first result (useful for pagination) |
| filters         | object  | Filter results with specific values |
| showGuided      | boolean | Whether or not to return search suggestions |

Full example:
```json
{
  "image": {"source": "http://www.cerebel.io/my_image.jpg"},
  "size": 20,
  "filters": {"source.gender": "women"},
  "showGuided": true
}
```


### Get item
Use the `item` endpoint to get a single item given its ID; e.g.:
```
curl https://api.cerebel.io/v3/store/faer/item/item_id?token=myReadToken
```

### Filtering
#### Term filters
You can use the `filters` field to return only results that match exactly a certain condition. For example, to return only results where `gender` is `women`:
```json
{
  "filters": {"source.gender": "women"},
}
```
You can also filter on the annotations:  
```json
{
  "filters": {"annotations.material": "cotton"},
}
```

#### Range filters
You can also use range filters over numeric fields. For example, to return results where the `price.eur` field is between `10` and `100` (exclusive), you can use:
```json
{
  "filters": {
    "price.eur": {
      "gt": 10,
      "lt": 100
    }
  }
}
```
The supported comparison primitives are: `gt`, `gte`, `lt` and `lte`.

#### Geo distance filters
Given a `location`, return only items that are within the `distance`.
```json
"filters": {
    "store_locations":  {
        "distance": "50km",
        "location":  {
            "lat": 53,
            "lon": 13
         }
    }
}
```

#### On sale filter
Return only products that are on sale.
```json
"filters": {
    "onSale": true
}
```

### Sorting
#### Sort by field
Example:
```json
"sortByField" {
    "price.eur": {
        "order": "asc"
    }
}
```

#### Sort by distance
Example:
```json
"sortByDistance" {
    "store_locations": {
        "location": {
            "lat": 53,
            "lon": 13
        },
        "order": "desc"
    }
}
```

### Aggregations
We support three different types of aggregation: `count`, `max` and `min`.
  
The `max` and `min` aggregations take a list of fields to aggregate on, and returns the max/min value for that field.
Example:
```json
{
  "query": "sneakers",
  "aggregations": {
    "max": {
      "fields": ["price.eur"]
    },
    "min": {
      "fields": ["price.eur"]
    }
  }
}
```
  
Example response:
```json
{
  "id": "VhDZrgzphV",
  "status": "ok",
  "matches": {
    "total": 149,
    "items": [
     ...
    ]
  },
  "aggregations": {
    "max": {
      "price.eur": 475
    },
    "min": {
      "price.eur": 35.94
    }
  }
}
```

The `count` aggregation takes the list of fields to aggregate on and an optional `topHits` integer that represents the number of items to return for that aggregation.
Example:
```json
{
    "query": "sneakers",
    "aggregations": {
      "count": {
        "fields": ["brand"],
        "topHits": 1,
      }
    }
}
```

Example response:
```json
{
  "id": "VhDZrgzphV",
  "status": "ok",
  "matches": {
    "total": 149,
    "items": [
     ...
    ]
  },
  "aggregations": {
    "brand": [
      {
        "value": "Beaumont Organic",
        "count": 187
      },
      {
        "value": "Everlane",
        "count": 72
      },
      {
        "value": "Reformation",
        "count": 38
      },
      {
        "value": "Kamperett",
        "count": 35
      },
      {
        "value": "Sezane",
        "count": 32
      },
      {
        "value": "Amour Vert",
        "count": 31
      },
      {
        "value": "IvanaHelsinki",
        "count": 31
      },
      {
        "value": "Loup",
        "count": 31
      },
      {
        "value": "Cortana",
        "count": 30
      },
      {
        "value": "Arnsdorf",
        "count": 29
      }
    ]
  },
  "query": {
    "intent": "search",
    "entities": [
      {
        "type": "category",
        "value": "trainers",
        "start": 0,
        "end": 1,
        "original": "sneakers"
      }
    ]
  },
  "took": 29,
}
```

### Guided search 
Suggests search terms that can be used to refine the query.
Example:
```json
{
    "query": "dress",
    "showGuided": true
}
```

Example response:
```json
{
  "id": "sSnfuuXvLY",
  "status": "ok",
  "matches": {
    "total": 1007,
    "items": [...]
  },
  "guided": [
    "striped",
    "print",
    "floral",
    "paisley",
    "herringbone",
    "black",
    "navy",
    "white",
    "blue",
    "red",
    "dark grey",
    "green",
    "cream",
    "light grey",
    "grey",
    "long",
    "sleeveless",
    "short sleeve",
    "short",
    "long sleeve"
  ],
  "query": {
    "intent": "search",
    "entities": [
      {
        "type": "category",
        "value": "dresses",
        "start": 0,
        "end": 1,
        "original": "dress"
      }
    ]
  },
  "took": 113
}
```

You can then append a suggestion to the current query, to get refined results:
```json
{
    "query": "dress floral",
    "showGuided": true
}
```

### Suggest
Returns autocomplete suggestions from a given prefix.  
  
If no prefix is given, a default set of suggestions is returned, based on popularity and diversity.

| Parameter       | Type    | Description |
| --------------- | ------- | ----------- |
| q               | string  | The search query text |
| size            | integer | Maximum number of results to return |
| gender          | string  | One of `men`, `women`. Leave empty for both genders |

Example:
```bash
curl https://api.cerebel.io/v3/store/faer/suggest?token=accessToken&q=la
```

Response:  
```json
{
  "id": "ctfvOlGgxA",
  "status": "ok",
  "suggestions": [
    {
      "value": "langerchen",
      "offset": 0,
    },
    {
      "value": "less too late",
      "offset": 9,
    },
    {
      "value": "laura siegel",
      "offset": 0,
    }
  ],
  "took": 4,
  "total": 3
}
```

`offset` tells you the position of the query in the suggestion.

### Teasers
Returns a pre-computed set of teasers to display in the search homepage.
  
| Parameter       | Type    | Description |
| --------------- | ------- | ----------- |
| gender          | string  | One of `men` or `women`. |
| lat             | float   | A latitude, used to compute nearby shops. |
| lon             | float   | A longitude, used to compute nearby shops. |
| distance        | string  | Radius in which nearby shops are located (e.g. "100km"). Defaults to "50km". |

Example:
```bash
curl https://api.cerebel.io/v3/store/faer/search/teasers?token=accessToken&gender=women&lat=52.520008&lon=13.404954
```

Response:  
```json
{
  "id": "ctfvOlGgxA",
  "status": "ok",
  "took": 0,
  "items": [
  {
    "type": "categories",
    "name": "Popular Categories",
    "items": [
      {
        "image_url": "https://storage.googleapis.com/assets.cerebel.io/images/faer/b5419189483743fd9801a5443df7d0ba4e2ba2a5f404fcff6346ba2c98fbc9d5-1.jpg",
        "title": "dresses"
      },
      {
        "image_url": "https://storage.googleapis.com/assets.cerebel.io/images/faer/96dff3fea76fab19e76f6ba4ae540236fe3399fa76dfd7e4eb1fd0a5602c22e6-1.jpg",
        "title": "trousers"
      },
      {
        "image_url": "https://storage.googleapis.com/assets.cerebel.io/images/faer/cf4ca2f627844905c81c47f2e936def83da7a4ad99a666105b3cda67f8b97a21-1.jpg",
        "title": "t-shirts"
      },
      {
        "image_url": "https://storage.googleapis.com/assets.cerebel.io/images/faer/5aa06d9e06ec42ec27be9ea5374fbeef7168ff46e31c9b3430cc6288af32151e-1.jpg",
        "title": "sweatshirts"
      },
      {
        "image_url": "https://www.cortana.es/en/wp-content/uploads/sites/2/2018/08/Kassar-coat-1-Cortana-Fall-Winter-18-1000x1500.jpg",
        "title": "coats"
      },
      {
        "image_url": "https://storage.googleapis.com/assets.cerebel.io/images/faer/4ff978e7adab1231304cb5781cfdf1c83385a486151db3ad29aa07b531d2e44e-1.jpg",
        "title": "tops"
      }
    ]
  },
  {
    "type": "map",
    "name": "Shops Around You"
    "items": [
      {
        "brand": "ARMEDANGELS",
        "name": "Pleek & Cobernbourg",
        "country": "Germany",
        "city": "Berlin",
        "address": "",
        "location": {
          "lat": 53.12,
          "lon": 13.01
        }
      ]
  },
  {
    "type": "categories",
    "name": "Brand Spotlight",
    "items": [
      {
        "title": "Amour Vert",
        "products": [...]
      },
      ...
    }
  }
}
```

`offset` tells you the position of the query in the suggestion.

## Product model
Example:
```json
{
  "id": "a080ea3b10e350fd90b0860c26fd2fdf2af2ba5d07cb10cbac752c265e5a8c8d",
  "vendor_id": "378393657371",
  "name": "Arnsdorf Logo Tee - Black with White Embroidery",
  "brand": "Arnsdorf",
  "url": "https://arnsdorf.com.au/collections/all/products/arnsdorf-logo-tee-black-with-white-embroidery",
  "gender": [
    "women"
  ],
  "description": "Available in both black and white, the Logo Tee is made from a soft organic cotton jersey and features a relaxed fit and short sleeves. The Arnsdorf logo is embroidered on the centre front. This classic tee will see you through the seasons and is perfect to pair with the Arnsdorf Denim range.  \n\nOur model Ruby wears a size S, and is 5'7\"/174cm. Her bust is 31\"/79cm, waist is 25.5\"/65cm and hips are 35\"/89cm.",
  "image_url": [
    "https://storage.googleapis.com/assets.cerebel.io/images/faer/a080ea3b10e350fd90b0860c26fd2fdf2af2ba5d07cb10cbac752c265e5a8c8d-1.jpg",
    "https://storage.googleapis.com/assets.cerebel.io/images/faer/a080ea3b10e350fd90b0860c26fd2fdf2af2ba5d07cb10cbac752c265e5a8c8d-2.jpg",
    "https://storage.googleapis.com/assets.cerebel.io/images/faer/a080ea3b10e350fd90b0860c26fd2fdf2af2ba5d07cb10cbac752c265e5a8c8d-3.jpg",
    "https://storage.googleapis.com/assets.cerebel.io/images/faer/a080ea3b10e350fd90b0860c26fd2fdf2af2ba5d07cb10cbac752c265e5a8c8d-4.jpg"
  ],
  "tags": [
    "black",
    "Cotton",
    "new",
    "tee",
    "tees",
    "Top",
    "tops"
  ],
  "price": {
    "eur": 74.5,
    "gbp": 65.5,
    "usd": 88,
    "dkk": 556,
    "sek": 763.5,
    "inr": 6022,
    "aud": 117.5
  },
  "variants": [
    {
      "vendor_id": "4839062372379",
      "vendor_sku": "LOGO-TEE-BLACK-WITH-WHITE-XS",
      "name": "XS",
      "available": true,
      "size": "xs"
    },
    {
      "vendor_id": "4839062405147",
      "vendor_sku": "LOGO-TEE-BLACK-WITH-WHITE-S",
      "name": "S",
      "available": true,
      "size": "s"
    },
    {
      "vendor_id": "4839062437915",
      "vendor_sku": "LOGO-TEE-BLACK-WITH-WHITE-M",
      "name": "M",
      "available": true,
      "size": "m"
    },
    {
      "vendor_id": "4839062470683",
      "vendor_sku": "LOGO-TEE-BLACK-WITH-WHITE-L",
      "name": "L",
      "available": true,
      "size": "l"
    },
    {
      "vendor_id": "4839062503451",
      "vendor_sku": "LOGO-TEE-BLACK-WITH-WHITE-XL",
      "name": "XL",
      "available": true,
      "size": "xl"
    }
  ],
  "annotations": {
    "brand": [
      "Arnsdorf"
    ],
    "category": [
      "t-shirts",
      "tops"
    ],
    "color": [
      "black",
      "white"
    ],
    "fabric": [
      "cotton"
    ],
    "gender": [
      "women"
    ]
  }
}
```

# Feed service

Exposes the feed API.  

See how to run the service [here](cmd/srv).  

See how to run the CLI tool [here](cmd/cli).

[API v3](#api-v3)  
- [HTTP](#http)  

---

## API v3

### HTTP

To get personalized results, you should pass a user ID in the headers. See below for an example.

#### List
```bash
curl -H "X-User-Id: 123-abc" https://api.cerebel.io/v3/store/faer/feed?token=accessToken
```
  
Optionally, you can pass a `gender` (`women` or `men`), a `size` parameter, and a `category` parameter.  


# Store service

Exposes the document ingestion API and encapsulates the document indexing pipeline.

See how to run the service [here](cmd/srv).  

See how to run the CLI tool [here](cmd/cli).  


[API](#api)  
- [gRPC](#grpc)  

---

## API

### gRPC

#### Connect to store host
```go
conn, err := grpc.Dial(storeHost, grpc.WithInsecure())
if err != nil {
    return errors.New("Could not connect to store!")
}
defer conn.Close()
client := pb.NewRecordStoreClient(conn)
```

#### Authorize the request
All requests to the Store, to the exception of `CreateStore` and `ListStores`, must be authenticated with an admin token.  
Place it in the call metadata:
```go
md := metadata.Pairs("X-Cerebel-Token", myAdminToken)
ctx := metadata.NewContext(context.Background(), md)
```

#### Create a record store

```go
client.CreateStore(ctx, &pb.CreateStoreRequest{
    AccountId: "my_account",
    StoreId:     "my_store",
    Language: "en",
    Fields: []*pb.FieldDescriptor{
        &pb.FieldDescriptor{
            Field: "id",
            Type: "text",
            Searchable: false,
            IsIdentifier: true,
        },        
        &pb.FieldDescriptor{
            Field: "name",
            Type: "text",
            Searchable: true,
        },        
    },
})
```

#### Get record store metadata

```go
response, _ := client.GetStoreMetadata(ctx, &pb.MetadataRequest{
    StoreId: "my_store",
})
```

#### Delete record store

```go
client.DeleteStore(ctx, &pb.DeleteStoreRequest{
    StoreId: "my_store",
})
```

#### List stores
Returns all stores for the authorized account.
```go
response, err := client.ListStores(ctx, &pb.ListStoresRequest{})
if err != nil {
    return err
}

for _, storeDesc := range response.Stores {
    jsonStr, _ := json.Marshal(storeDesc)
    fmt.Println(string(jsonStr))
}
```

#### Import status
Returns the status of a job.  
```go
request := &pb.ImportStatusRequest{
    JobId: "abc123",
}
response, err := client.GetImportStatus(ctx, request)
if err != nil {
	return err
}
```

#### Schedule import
Schedules a full import with given period.  
```go
request := &pb.ScheduleImportRequest{
    StoreId: "my_store",
    Url: "http://my_catalog.jsonlines",
    FrequencyHours: 24,
}
response, err := client.ScheduleImport(ctx, request)
if err != nil {
	return err
}
```

#### Get schedule
Returns the import schedule for the given store.  
```go
request := &pb.GetImportScheduleRequest{
    StoreId: "my_store",
}
response, err := client.GetImportSchedule(ctx, request)
if err != nil {
    return err
}
```

# User service

Exposes the User API.  

See how to run the service [here](cmd/srv).  

[API v3](#api-v3)  
- [HTTP](#http)  

---

## API v3

### HTTP

#### Get a user
```bash
curl https://api.cerebel.io/v3/store/faer/user/:ID
```

#### Delete a user
```bash
curl -XDELETE https://api.cerebel.io/v3/store/faer/user/:ID
```

#### Update or create a user if it doesn't exist
```bash
curl -XPUT https://api.cerebel.io/v3/store/faer/user/:ID -d '{"fcm_token": "123"}'
```


# Brand service

Exposes the Brand API.  

See how to run the service [here](cmd/srv).  

[API v3](#api-v3)  
- [HTTP](#http)  

---

## API v3

### HTTP

#### Get a brand
```bash
curl https://api.cerebel.io/v3/store/faer/brand/:ID?token=:TOKEN&gender=:GENDER
```
