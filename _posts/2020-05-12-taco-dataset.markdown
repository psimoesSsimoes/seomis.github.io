---
layout: post
title: Image Dataset for Litter Detection
date: 2020-05-17 01:00:00 +0300
description: Open image dataset of waste in the wild. # Add post description (optional)
img: taco.gif # Add image post (optional)
tags: [TACO, COCO, MachineLearning, Annotations, Dataset, ObjectSegmentation, DeepLearning] # add tag
---
### Today i want to talk a bit about a project from the mind of the idealist and wizard [Pedro Proença](https://pedropro.github.io/).

It is called [TACO](http://tacodataset.org/), which stands for Trash Annotations in Context, and it is an open image dataset for litter detection, similar to [COCO object segmentation](http://cocodataset.org/). It contains photos of litter taken under diverse environments, from tropical beaches to London streets. These images are manually labeled and segmented according to a hierarchical taxonomy to train and evaluate object detection algorithms.

### Why is TACO needed?

Humans have been trashing planet Earth from the bottom of [Mariana trench](https://www.nationalgeographic.com/news/2018/05/plastic-bag-mariana-trench-pollution-science-spd/) to [Mount Everest](https://www.livescience.com/63061-how-much-trash-mount-everest.html). [Every minute, at least 15 tonnes of plastic waste leak into the ocean](http://www3.weforum.org/docs/WEF_The_New_Plastics_Economy.pdf), that is equivalent to the capacity of one garbage truck. We have all seen the impact of this behaviour to wildlife on images of turtles choking on plastic bags and birds filled with bottle caps. Recent studies have also found microplastics in human stools. These should be kept in the recycling chain not in our food chain.

We believe AI has an important role to play. Think of drones surveying trash, robots picking up litter, anti-littering video surveillance and AR to educate and help humans to separate trash. That is our vision. All of this is now possible with the recent advances of [deep learning](https://www.youtube.com/watch?v=Cgxsv1riJhI). However, to learn accurate trash detectors, deep learning needs many [annotated images](https://www.youtube.com/watch?v=40riCqvRoMs). While there are a few other trash datasets, we believe these are not enough and therefore we created TACO.

### TACO Features

  - Object segmentation. Typically used bounding boxes are not enough for certain tasks, e.g., robotic grasping
  - Images under free licence. You can do whatever you want with TACO as long as you cite us.
  - Background annotation. TACO covers many environments which are tagged for convenience.
  - Object context tag. Not all objects in TACO are strictly litter. Some objects are handheld or not even trash yet. Thus, objects are tagged based on context.

### The Dataset

TACO  contains  high  resolution  images,  taken  mostly  by  mobile  phones.  These  are  managed  and stored by Flickr, whereas our server manages the annotations and  runs  periodically  a  crawler  to  collect  more  potential images of litter. Images are labeled with the scene tags,  to  describe  their  background  –  these  are  not mutually exclusive – and litter instances are segmented and labeled using [a hierarchical taxonomy with 60 categories of litter  which  belong  to  28  super  (top)  categories  ,including  a  special  category:Unlabeled litterforobjects  that  are  either  ambiguous  or  not  covered  by  the other categories](http://tacodataset.org/taxonomy). This is fundamentally different from other datasets  (e.g.  COCO)  where  distinction  between  classes  is key.  Here, all  objects  can  be in  fact  classified as  one  class: **litter**.  Furthermore,  it  may  be  impossible  to  distinguish visually  between  two  classes,  e.g.,  plastic  bottle  and  glassbottle. Given this ambiguity and the class imbalance, classes can be rearranged to suit a particular task.

## How can one help?

   - Annotations are key to improve the dataset and TACO is officially open for [new annotations](http://tacodataset.org/annotate).
   - Litter image submission is also important and can be done [here](http://tacodataset.org/upload) or to Flickr following our [instructions](http://tacodataset.org/flickr_instructions).
   - Use dataset: If you are interested in machine learning, check out [our repo](https://github.com/pedropro/TACO) and start using this dataset in your experiments. We would love to hear about your results.
   - Feedback is appreciated. Let us know if you spot any issue with the dataset or our tools.

This blog was originally posted on [Medium](https://medium.com/@seomisw/image-dataset-for-litter-detection-7f1cab9e7fa1){:target="_blank"}--be sure to follow and clap!
