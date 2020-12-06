---
layout: post
title: When Go will return free memory back to the operating system?
date: 2020-12-06 09:00:00 +0300
description: # Add post description (optional)
img: memory_golang.png # Add image post (optional)
tags: [Golang,OS,Memory,Observability] # add tag
---
### TIL that golang (1.15) is not immediately freeing the heap memory, at least from OS perspective.

I stumbled into this characteristic after some stress tests to an API. I could see memory being allocated to the process without ever being freed.

It was time to dig into golang memory management, and find what was happening.

### Some OS concepts first.

- Address Space =

/* This blog was originally posted on [Medium](https://medium.com/@seomisw/image-dataset-for-litter-detection-7f1cab9e7fa1){:target="_blank"}--be sure to follow and clap! */
