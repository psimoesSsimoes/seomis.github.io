---
title: 'Bash + ElasticSearch MultiSearch'
date: 2021-04-10 01:00:00
featured_image: '/images/elastic-bash/shell-script-logo.jpg'
excerpt: Trying to automate common searches on ElasticSearch using Bash.
---

![](/images/elastic-bash/shell-script-logo.jpg)


---

### Correlating logs on ElasticSearch using Kibana is usually pretty easy.

In Distributed Systems, if **System Y** performs a request to **System X**, you can use attributes like **transaction_id**, **trace_id** and **span_id** to navigate all logs belonging to a particular trace, and vice-versa.

But sometimes you have systems interacting which have **no good log correlation**. You could be still in MVP phase, or the system calling is a legacy system that no one want to touch, or even that the logs between systems are not structured in a way that is easy to query data.

You'll find yourself looking in surrounding documents near the log you are interested in, or blindingly looking in some other system logs for some information that helps you understand some situation... and if your systems produce **a lot** of log data, finding the information you want can easily feel like finding a needle on a waystack.

Well... i found myself in this situation this week ¯\(シ)/¯ .

Fortunately, the information i was searching for was always on the surrounding documents of some specific log.

> So i thought: Ok, I'll spend 20 min of my weekend automating this.

Or so i thought...

---
## The basic idea

Should be simple enough: Open browser developer tools, click the Kibana log link of `View Surrounding Documents`, [copy as curl](https://everything.curl.dev/usingcurl/copyas). Tune some of the request fields, perform the request and  use [jq](https://github.com/stedolan/jq) to look up the fields i want.

The original curl (redacted, and without headers) is similar to this one:


```html
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

The request makes use of the [newline delimited JSON](http://ndjson.org/) NDJSON format. In simpler terms, it follows the following structure:

```html
Header\n
Body\n
Header\n
Body\n
```

In a quick look i could see that two headers and two body, so it is performing **two** searches.

Each header contains the following information:

```json
{
	"index": "logstash-default*",
	"ignore_unavailable": true,
	"preference": 12353564645
}
```

* index: the index we are using
* preference: preference of which shard copies on which to execute the search
* ignore_unavailable: missing or closed indices are not included in the response if true (which is the case).

The two bodies have a similar format:

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

The important fields are the following:

* size : the number of hits to return
* search_after: works as a live cursor, where we have [offset,limit]
* sort : we are sorting by timestamp asc
* query: it's using a range query to return documents within the provided range.


Now it is clear what the curl is doing: it is using the unix timestamp of a particular record to retrieve the 5 previous and following records.

_So, if we give it the unix timestamp of the record, we should be able to obtain the neibouring information._

---
### Now that we understand the request, we need to retrieve the information we are looking for on surrounding docs.

For that, i have choosen the following [jq](https://github.com/stedolan/jq) filter:

```
jq '.responses[0].hits.hits[] | ._source.payload.fields.<field_i_am_looking_for>'
```

we use the first array index of responses and we will return all of the elements of an array **hits**. We use the [Pipe](https://stedolan.github.io/jq/manual/#Basicfilters) operator to run a filter for each of those results. In my case i want to retrieve fields _source.payload.fields.<the field that i am looking for>_.


### Good! Now, we are ready to write some bash.

I want to receive as input three fields:

* an unix timestamp which i'll use to look around.
* the number of records i'll want to look around.
* the field i am looking for.

To handle cmd input, i've written the following:

```bash
helpFunction()
{
   echo ""
   echo "Usage: $0 --sort <sort_id> --around <number_of_entries> --field <the field name i am looking for>"
   echo -e "\t--sort sort field found on json entry"
   echo -e "\t--size number of surrounding documents"
   echo -e "\t--field field you are looking"
   exit 1
}

ARGUMENT_LIST=(
    "sort"
    "around"
    "field"
)


# read arguments
opts=$(getopt \
    --longoptions "$(printf "%s:," "${ARGUMENT_LIST[@]}")" \
    --name "$(basename "$0")" \
    --options "" \
    -- "$@"
)

eval set --$opts

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sort)
            argOne=$2
            shift 2
            ;;

        --around)
            argTwo=$2
            shift 2
            ;;

        --field)
            argThree=$2
            shift 2
            ;;
        --) shift ; break ;;
    esac
done

# Print helpFunction in case parameters are empty
if [ -z "$argOne" ] || [ -z "$argTwo" ]|| [ -z "$argThree" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

```

Now that we have the cmd input, we need to calculate the around timestamps:

```bash
around_1=$(( $argOne + 86400000 ))
around_2=$(( $argOne + 1985122 ))
```

And now we just need to call the curl!

So, until this point i had spent some and less 20 min to do this.

Performing the curl with user input should be the easy part. Except it wasn't :P

All because i didn't knew the meaning of **--data-raw $'{}**.

The notation $'...' is a special form of quoting a string. Strings that are scanned for [ANSI C like escape sequences](https://www.gnu.org/software/bash/manual/html_node/ANSI_002dC-Quoting.html#ANSI_002dC-Quoting).

So an example of what i was trying to do:

```bash
curl something -d $'{"somefield1":'$argOne',"somefield2":'$argTwo'}'
```

when in fact i should be doing:

```bash
curl something -d $'{"somefield1":'$argOne$',"somefield2":'$argTwo$'}'
```

Did you notice that single **$** after the variable and before the string? It took me more than an hour to discover this!


But hey! i got it working \m/

So all together, the gist can be found [here](https://gist.github.com/psimoesSsimoes/18d7e478d010994d9f5bb3907516dbf6)


### And the main lesson i learned : Words of the form $'string' are treated specially. The word expands to string, with backslash-escaped characters replaced as specified by the ANSI C standard
---
