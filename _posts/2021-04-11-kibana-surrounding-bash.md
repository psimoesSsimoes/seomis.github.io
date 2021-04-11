---
title: 'Bash script Kibana Surrounding Documents'
date: 2021-04-10 01:00:00
featured_image: '/images/taco/shell-script-logo.jpg'
excerpt: Some lessons from trying to automate common searches on Kibana using Bash.
---

![](/images/taco/shell-script-logo.jpg)


Correlating logs on ElasticSearch using Kibana is usually pretty easy. In distributed systems, if System Y performs a request to system X, if you use an request-id header with some unique value, you can correlate the logs on both systems.
Another common form would be using a correlation ID or use information as the ip address.

But sometimes you have systems interacting which have no good log correlation. You could be still in MVP phase, or the system calling is a legacy system that no one want to touch, or even that the logs between systems are not structured in a way that is easy to query data, or even that right now it is too expensive for some of the teams to restructure the logs to allow a better correlation.

You'll find yourself looking in surrounding documents near the log you are interested in, or blindingly looking in some other system logs for some information that helps you understand some situation. If your systems produce a lot of log data, finding the information you want can easily feel like finding a needle on a waystack.

Well... i found myself in this situation this week :sweat_smile:

Fortunately, the information i was searching for was always on the surrounding documents of some specific log.

So i thought: Ok, I'll spend 20 min of my weekend automating this.


## The basic idea

Should be simple enough: Open browser developer tools, click the Kibana log link of `View Surrounding Documents`, copy as curl. Then, use *sort* field of the document , and tune the fields
