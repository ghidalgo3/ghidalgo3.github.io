---
layout: post
title:  "Fun with jq"
date:   2021-07-24 12:34:23 -0400
categories: tools
---

# What is `jq`?
[`jq`](https://stedolan.github.io/jq/tutorial/) is a wonderful tool for processing JSON in the command line. 
The prevalence of JSON in web APIs and data dumps makes `jq` a very imporant tool for interactively manipulating JSON.
The [tutorial](https://stedolan.github.io/jq/tutorial/) is good enough to get you started with basic functionality, but I found that real usage quickly outgrew the scope of the tutorial.
In this post I will show examples of using `jq` in slightly more complex scenarios than the tutorial.

The data in this post comes from [Yelp's Dataset Challenge](https://www.yelp.com/dataset/documentation/main), and I will be focusing on the business data file (that is `yelp_academic_dataset_business.json` if you're following at home).

# Formatting

Usually I like to look at one row of a dataset to understand the data schema.
The Yelp data contains one entry per line, so we can use `head -n 1` argument to get the first line of the data file and inspect the schema.

```
> head -n1 yelp_academic_dataset_business.json 
{"business_id":"6iYb2HFDywm3zjuRg0shjw","name":"Oskar Blues Taproom","address":"921 Pearl St","city":"Boulder","state":"CO","postal_code":"80302","latitude":40.0175444,"longitude":-105.2833481,"stars":4.0,"review_count":86,"is_open":1,"attributes":{"RestaurantsTableService":"True","WiFi":"u'free'","BikeParking":"True","BusinessParking":"{'garage': False, 'street': True, 'validated': False, 'lot': False, 'valet': False}","BusinessAcceptsCreditCards":"True","RestaurantsReservations":"False","WheelchairAccessible":"True","Caters":"True","OutdoorSeating":"True","RestaurantsGoodForGroups":"True","HappyHour":"True","BusinessAcceptsBitcoin":"False","RestaurantsPriceRange2":"2","Ambience":"{'touristy': False, 'hipster': False, 'romantic': False, 'divey': False, 'intimate': False, 'trendy': False, 'upscale': False, 'classy': False, 'casual': True}","HasTV":"True","Alcohol":"'beer_and_wine'","GoodForMeal":"{'dessert': False, 'latenight': False, 'lunch': False, 'dinner': False, 'brunch': False, 'breakfast': False}","DogsAllowed":"False","RestaurantsTakeOut":"True","NoiseLevel":"u'average'","RestaurantsAttire":"'casual'","RestaurantsDelivery":"None"},"categories":"Gastropubs, Food, Beer Gardens, Restaurants, Bars, American (Traditional), Beer Bar, Nightlife, Breweries","hours":{"Monday":"11:0-23:0","Tuesday":"11:0-23:0","Wednesday":"11:0-23:0","Thursday":"11:0-23:0","Friday":"11:0-23:0","Saturday":"11:0-23:0","Sunday":"11:0-23:0"}}
```
😅 A little hard to read. Let's pipe that into `jq`
```
> head -n1 yelp_academic_dataset_business.json | jq
{
  "business_id": "6iYb2HFDywm3zjuRg0shjw",
  "name": "Oskar Blues Taproom",
  "address": "921 Pearl St",
  "city": "Boulder",
  "state": "CO",
  "postal_code": "80302",
  "latitude": 40.0175444,
  "longitude": -105.2833481,
  "stars": 4,
  "review_count": 86,
  "is_open": 1,
  "attributes": {
    "RestaurantsTableService": "True",
    "WiFi": "u'free'",
    "BikeParking": "True",
    "BusinessParking": "{'garage': False, 'street': True, 'validated': False, 'lot': False, 'valet': False}",
    "BusinessAcceptsCreditCards": "True",
    "RestaurantsReservations": "False",
    "WheelchairAccessible": "True",
    "Caters": "True",
    "OutdoorSeating": "True",
    "RestaurantsGoodForGroups": "True",
    "HappyHour": "True",
    "BusinessAcceptsBitcoin": "False",
    "RestaurantsPriceRange2": "2",
    "Ambience": "{'touristy': False, 'hipster': False, 'romantic': False, 'divey': False, 'intimate': False, 'trendy': False, 'upscale': False, 'classy': False, 'casual': True}",
    "HasTV": "True",
    "Alcohol": "'beer_and_wine'",
    "GoodForMeal": "{'dessert': False, 'latenight': False, 'lunch': False, 'dinner': False, 'brunch': False, 'breakfast': False}",
    "DogsAllowed": "False",
    "RestaurantsTakeOut": "True",
    "NoiseLevel": "u'average'",
    "RestaurantsAttire": "'casual'",
    "RestaurantsDelivery": "None"
  },
  "categories": "Gastropubs, Food, Beer Gardens, Restaurants, Bars, American (Traditional), Beer Bar, Nightlife, Breweries",
  "hours": {
    "Monday": "11:0-23:0",
    "Tuesday": "11:0-23:0",
    "Wednesday": "11:0-23:0",
    "Thursday": "11:0-23:0",
    "Friday": "11:0-23:0",
    "Saturday": "11:0-23:0",
    "Sunday": "11:0-23:0"
  }
}
```
Much easier to read! 
## Format the whole file
To completely format a file, we can pipe all lines into `jq` and then redirect the result to a file:
```
> cat yelp_academic_dataset_business.json | jq > yelp_academic_dataset_business_formatted.json
```
> Caution, this file is not valid JSON! It is only useful for reading through the data in a text editor.

# Filtering

Let's say we wanted to find all of the restaurants with ratings >= 4 and with more than 5 reviews.
We can do it like this:
```
> cat yelp_academic_dataset_business.json | jq --compact-output 'select(.review_count > 5 and .stars >= 4)' > high_ratings.json
```
> Note that I used `--compact-output` to preserve the 1-object-per-line structure of the original file. Without this option, `high_ratings.json` would contain nicely formatted JSON.

The syntax is very easy: `jq 'select(<boolean expression>)'` will filter objects where the boolean expression returns false.

# Selecting
Or sometimes called projections, I will show 2 cases building on the previous filter example.
## Select JSON to value
```sh
cat yelp_academic_dataset_business.json | jq --compact-output 'select(.review_count > 5 and .stars >= 4) | .business_id' > high_ratings.json
```

After the `select` call, I pipe the resulting object into a property access `.business_id`. 
This produces a file that looks like:
```
"6iYb2HFDywm3zjuRg0shjw"
"tCbdrRPZA0oiIYSmHG3J0w"
"bvN78flM8NLprQ1a1y5dRg"
"PE9uqAjdw0E4-8mjGl3wVA"
```

## Select JSON to JSON
```
cat yelp_academic_dataset_business.json | jq --compact-output 'select(.review_count > 5 and .stars >= 4) | {business_id}' > high_ratings.json
```

Note that the syntax `| {business_id}` is a shortcut for `| {"business_id": .business_id}`, the latter case can be useful if you want to rename a property or product a new property from different values.
This produces a file that looks like:
```
{"business_id":"6iYb2HFDywm3zjuRg0shjw"}
{"business_id":"tCbdrRPZA0oiIYSmHG3J0w"}
{"business_id":"bvN78flM8NLprQ1a1y5dRg"}
{"business_id":"PE9uqAjdw0E4-8mjGl3wVA"}
```

# JSON to [C|T]SV
JSON is a very self-documenting format for data, which is great for humans but not very useful for computers.
If I wanted to do some basic analysis on this data, the first thing I would do is load it into a spreadsheet program and start generating some graphs.
To do that, we need to transform this file into a comma-separated value file or a tab-separated value file.

Unfortunately any command to transform JSON to CSV on anything but the most basic JSON has to make choices about what to do with object and array properties (recursively) so there is no easy answer.
The `jq` filter we write depends on the source data and how we want the CSV to look like.

Or does it?
Denizens of the internet have graciously provided a `jq` filter to perform this for arbitrary JSON.
This filter takes advantage of `jq`'s programming features: that's right, `jq` is its own little programming language!
Gaze your eyes on this:
```
def json2header:
  [paths(scalars)];

def json2array($header):
  [$header[] as $p | getpath($p)];

# given an array of conformal objects, produce "CSV" rows, with a header row:
def json2csv:
  (.[0] | json2header) as $h
  | ([$h[]|join(".")], (.[] | json2array($h))) 
  | @csv ;

# `main`
json2csv
```

Put this into a file called `json2csv.jq` and invoke it like this:

```
jq -rf json2csv.jq yelp_academic_dataset_business.json
```

Don't forget to turn the json file into an array of objects first with something like:
```
> head -n 3 yelp_academic_dataset_business.json | jq -s '.' > high_ratings.json
```

Big thanks to [this](https://stackoverflow.com/questions/32960857/how-to-convert-arbitrary-simple-json-to-csv-using-jq) and [this](https://stackoverflow.com/questions/57242240/jq-object-cannot-be-csv-formatted-only-array) StackOverflow question.

# Conclusion
`jq` is great!
