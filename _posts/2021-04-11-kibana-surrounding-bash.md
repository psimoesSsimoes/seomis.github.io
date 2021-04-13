---
title: 'Bash + ElasticSearch MultiSearch'
date: 2021-04-10 01:00:00
featured_image: '/images/elastic-bash/shell-script-logo.jpg'
excerpt: Trying to automate common searches on ElasticSearch using Bash.
---

![](/images/elastic-bash/shell-script-logo.jpg)


---

### Correlating logs on ElasticSearch using Kibana is usually pretty easy.

In Distributed Systems, if **System Y** performs a request to **System X**, you can use attributes like **transaction_id**, **trace_id** and **span_id** to navigate all logs belonging to a particular trace, and vice-versa — for a specific log, see in which context it has been logged, and which parameters the user provided.

But sometimes you have systems interacting which have **no good log correlation**. You could be still in MVP phase, or the system calling is a legacy system that no one want to touch, or even that the logs between systems are not structured in a way that is easy to query data.

You'll find yourself looking in surrounding documents near the log you are interested in, or blindingly looking in some other system logs for some information that helps you understand some situation... and if your systems produce **a lot** of log data, finding the information you want can easily feel like finding a needle on a waystack.

Well... i found myself in this situation this week :sweat_smile:

Fortunately, the information i was searching for was always on the surrounding documents of some specific log.

> So i thought: Ok, I'll spend 20 min of my weekend automating this.

Or so i thought...

## The basic idea

Should be simple enough: Open browser developer tools, click the Kibana log link of `View Surrounding Documents`, [copy as curl](https://everything.curl.dev/usingcurl/copyas). Tune some of the request fields, perform the request and  use [jq](https://github.com/stedolan/jq) to look up the fields i want.

The original curl (redacted, and without headers) is similar to this one:


```curl
curl 'https://<some_endpoint>/_msearch?rest_total_hits_as_int=true&ignore_throttled=true'
--data-raw $'{"index":"logstash-default*","ignore_unavailable":true,
"preference":1618072435228}\n{"size":5,"search_after":[1618071886078,23742571],
"sort":[{"@timestamp":{"order":"asc","unmapped_type":"boolean"}},{"_doc":{"order":"desc","unmapped_type":"boolean"}}],
"version":true,"_source":{"excludes":[]},"stored_fields":["*"],"script_fields":{},
"docvalue_fields":[{"field":"@timestamp","format":"date_time"}],
"query":{"bool":{"must":[{"constant_score":{"filter":{"range":{"@timestamp":{"format":"epoch_millis","gte":1618071886078,"lte":1618158286078}}}}}],
"filter":[],"should":[],"must_not":[]}},"timeout":"30000ms"}\n{"index":"logstash-default*","ignore_unavailable":true,"preference":1618072435228}\n
{"size":5,"search_after":[1618071886078,23742571],"sort":[{"@timestamp":{"order":"desc","unmapped_type":"boolean"}},
{"_doc":{"order":"asc","unmapped_type":"boolean"}}],"version":true,
"_source":{"excludes":[]},"stored_fields":["*"],"script_fields":{},
"docvalue_fields":[{"field":"@timestamp","format":"date_time"}],
"query":{"bool":{"must":[{"constant_score":{"filter":{"range":{
"@timestamp":{"format":"epoch_millis","lte":1618071886078,"gte":1617985486078}}}}}],
"filter":[],"should":[],"must_not":[]}},"timeout":"30000ms"}\n'
```

Ok, this big curl thing that you probably cannot see in your mobile phone screen, uses [multisearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-multi-search.html) to execute several searches with a single API request.

The request makes use of the newline delimited JSON (NDJSON) format. Or in simpler terms, it follows the following structure:

```
Header\n
Body\n
Header\n
Body\n
```

In a quick look i can see that i have two headers and two body, so it is performing two searches.

The header tells us the **index** we are using, **preference** (preference of which shard copies on which to execute the search) and **ignore_unavailable** ( missing or closed indices are not included in the response).

The body is long have:

```json
{
  "size": 5,
  "search_after": [
    1618071886078,
    23742571
  ],
  "sort": [
    {
      "@timestamp": {
        "order": "asc",
        "unmapped_type": "boolean"
      }
    },
    {
      "_doc": {
        "order": "desc",
        "unmapped_type": "boolean"
      }
    }
  ],
  "version": true,
  "_source": {
    "excludes": []
  },
  "stored_fields": [
    "*"
  ],
  "script_fields": {},
  "docvalue_fields": [
    {
      "field": "@timestamp",
      "format": "date_time"
    }
  ],
  "query": {
    "bool": {
      "must": [
        {
          "constant_score": {
            "filter": {
              "range": {
                "@timestamp": {
                  "format": "epoch_millis",
                  "gte": 1618071886078,
                  "lte": 1618158286078
                }
              }
            }
          }
        }
      ],
      "filter": [],
      "should": [],
      "must_not": []
    }
  },
  "timeout": "30000ms"
}
```
