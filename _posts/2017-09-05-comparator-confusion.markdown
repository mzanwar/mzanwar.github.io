---
layout: post
title: "Comparator Confusion?"
date: "2017-09-05 00:00:15 -0500"
author: "Zeshan Anwar"
---

The comparator compare method is bad design! There I said it. It is non-intuitive and absurd. Unless I'm missing some really big insight here, I don't think I'm the only one confused.

I searched the web for an explanation and could not find anything that satisfied my curiosity. I found pages and pages of example of how to use it - but nothing describing the mechanism behind it. Someone even posted a question asking just [that][1]; and sadly was given a less than ideal answer.  Let me explain - here is a simple comparator implemented as a lambda function:

{% highlight java %}
  Comparator<Integer> sortAscending = (a, b) -> a - b;
{% endhighlight %}

Can you see where the confusion lies? Why does the subtraction of `a - b` result in a sort of ascending order? `a` and `b` are simply parameters to the function; they don't inherently provide any insight into what they are.

To  add to the confusion, by simple swapping the two parameters, namely `b - a`, we end up with a sort in ascending order.

{% highlight java %}
  Comparator<Integer> sortDescending = (a, b) -> b - a;
{% endhighlight %}

The key to understanding this is the following two points:
 1. How does the return value of `compare` affect final ordering?
 2. Which order are the parameters passed into the compare method - namely what are `a` and `b`?

The official [javadocs][2] do a reasonable job explaining 1. but they fall short on explaining what `a` and `b` are.

In short, if the `compare` method returns a negative number, `a` will always precede `b` in the final sorted order. If, however, compare returns a positive number, `b` will always precede `a` in ordering. Let me repeat that for clarity: *the return value of the compare method determines the final sorted placement of the two parameters, `a` and `b` with respect to each other.*

Now that we now how critical, we still don't know why `a - b` gives us ascending order; and `b - a` gives us descending.

Numbers have a natural order to them. 7 is bigger than 5 which is greater than 3. Likewise, 2 is less than 3. Subtract a bigger number from a smaller one and you end up with a positive value.

Let me illustrate with an example:
1: `(a, b) -> (a - b)`

   `(7, 3) -> (7 - 3)` => positive value meaning `3` come before `7` in the final order.

   `(3, 7) -> (3 - 7)` => -4: negative number, `3` will come before `7` again.

Both results give us ascending order; which is correct.

2: `(a, b) -> (b - a)`

   `(7, 3) -> (3 - 7)` => negative value; `7` comes before `3` in the final order.
   `(3, 7) -> (7 - 3)` => positive value; `3` comes before `7` in the final order.



### Misc

In my research of Java implementation of sorting; I came across the sorting algorithm that Java uses for its sorting. It's called [Tims Sort][3] and is a hybridized form of Merge sort. Check it out, its pretty cool.

> A stable, adaptive, iterative mergesort that requires far fewer than n lg(n) comparisons when running on partially sorted arrays - Tims Sort


[1]:https://stackoverflow.com/questions/26107921/what-determines-ascending-or-descending-order-in-comparator-comparable-collect
[2]:http://docs.oracle.com/javase/7/docs/api/java/util/Comparator.html
[3]:http://svn.python.org/projects/python/trunk/Objects/listsort.txt
