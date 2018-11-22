---
layout: post
title: "Confounded Comparator"
date: "2017-09-05 00:00:15 -0500"
author: "Zeshan Anwar"
---

![confused](https://media.giphy.com/media/3o7btPCcdNniyf0ArS/giphy.gif)

```java
Comparator<Integer> sort = (a,b) -> a - b;
```

How many times have we seen something the comparator compare method defined as the subtraction of two arbitrary entities? **This is bad code**! It is non-intuitive and absurd. Unless I'm missing some really big insight here, I firmly believe I’m not the only one this has confused.

After searching the searched the web for an explanation and could not find anything that satisfied my curiosity. I found pages and pages of example of how to use it - but nothing describing the mechanism behind it. Someone even posted an enticing [question][1]; and sadly was given a less than ideal answer.  

Let me explain - here is a simple comparator implemented as a lambda function:

```java
Comparator<Integer> ascending = (a,b) -> a - b;
Comparator<Integer> descending = (a, b) -> b - a;
```

Can you see where the confusion lies? Why does the subtraction of `a - b` result in a sort of ascending order?
`a` and `b` are simply parameters to the function; they don't inherently provide any insight into what they are. To add to the confusion, by simple swapping the subtraction, namely `b - a`, we end up with a descending order.

```java
Integer[] numbers = {4, 5, 2, 9, 1};
Arrays.sort(numbers, ascending); // {1, 2, 4, 5, 9}
Arrays.sort(numbers, descending); // {9, 5, 4, 2, 1}
```

Weird right!

### Breaking it down

The key to understanding this is understanding:
  1. The return value of `compare` affects the final ordering.
  2. Which order are the parameters passed into the compare method - namely what are `a` and `b`?

The official [javadocs][2] do a reasonable job explaining the first point but they fall short on explaining what `a` and `b` are.

In short, if the `compare` method returns a negative number, `a` will always precede `b` in the final sorted order. If, however, compare returns a positive number, `b` will always precede `a` in ordering. Let me repeat that for clarity: *the return value of the compare method determines the final sorted placement of the two parameters, `a` and `b` with respect to each other.*

A thing to note is the `compare` method does not know or care about what the words ascending or descending mean. All it wants to do is place two elements in some order. More precisely, it just wants to *pick* one element over the other.

Now we still don't know why `a - b` gives us ascending order; and `b - a` gives us descending. To add to the confusion, the switching of parameters `a- b` to `b - a` to reverse the sort, seems to imply that the order in which `a` and `b` are passed seems to affect final order. What we will discover shortly, however, is that this is **not** the case.

#### A natural order

Numbers have a natural order to them. 7 is bigger than 5. Likewise, 5 is smaller than 6. Subtract a smaller number from a bigger one and you end up with a positive value.  A smaller number minus a bigger one results in a negative value. This beckons the question: how do we know if a number is bigger or smaller than another? Instinctively, we picture a number line and plot the two points on it. The number that is furthest to the right is the bigger one. This is exactly what we are testing when we subtract the two inside our comparator function.

Let me illustrate with some examples: `Notation (a, b) -> (a - b)`

```
a = 7, b = 3
compare(a, b) -> (a - b)
(7, 3) -> (7 - 3)
7 - 3 = 4
```
4 is a positive value meaning `3` precedes `7` in the final sorted order; or put in other words: `b` comes before `a`.


Let's flip our parameters:
```
a = 3, b = 7
compare(a, b) -> (a - b)
(3, 7) -> (3 - 7)
3 - 7 = -4
```

-4 is a negative number, and thus `3` will come before `7` again. Put in other words: `b` comes before `a`.

Both results give us ascending order; which is correct. What we have just realized is that the order we pass into the function does not matter. But then what happens if we switch the parameters `(b - a)`

Lets try our first example again: `Notation (a, b) -> (b - a)`

```
a = 7, b = 3
compare(a, b) -> (b - a)
(7, 3) -> (3 - 7) => negative value;`7` comes before `3`
```
-4 is a negative number so `7` precedes `3` in final order. But hold on, what just happened here. I thought we just concluded above that the order we passed the numbers into the comparator function didn't matter.

By swapping the input parameters `a` and `b`, we've flipped our choice and this reverses the sort order. If a negative result would've selected `a` the first time, now we're gonna select `b`.

Where before, `(a - b)` returning a positive number the algorithm would pick b, `(b - a)` will return a negative number and so it'll select `a` this time. This works vice-versa.

>What we need to realize is that the `(b - a)` or `(a - b)` part doesn't really matter. What matters is the return value of the `compare` method.

```java
if compare(a, b) < 0, pick a;
if compare(a, b) > 0, pick b;
```

This means we can do all sorts of crazy stuff like this:

```java
Integer[] numbers = {4, 5, 2, 9, 1};
Comparator<Integer> crazySort = (a, b) -> {
       if (a == 5) return -1;
       if (a - b > 1) return -1; // pick a
       return a - b;
       };

Arrays.sort(numbers, crazySort);  // [1, 9, 2, 5, 4]
```



#### Why is `Comparator<Integer> sort = (a,b) -> a - b;` problematic?

`a-b` and `b-a` is a terrible hack. It's a bad abstraction and someone trying to be too clever. As is the case with clever solutions, they catch on and permeate throughout the web. For some odd reason, people are inexplicably drawn to these solutions.

You will find several accepted solution on StackOverflow implementing the comparator as `a - b`. This will work in 98% of scenarios, but why implement a flawed solution to begin with. The 2% of the time it does fail will be extremely hard to debug.

Other than being non-intuitive and confusing on first glance, this approach actually has a flaw. It fails when the values of `a` or `b` approach `Integer.MIN_VALUE` / `Integer.MIN_VALUE`. The better way to write this is the following:

```scala
// Better way
def ascendingSort = (a, b) -> {
    if a < b return -1 // order a before b
    if b < a return 1 // order b before a
    return 0
}
```

**Some more problems:**

1. How do we sort objects that don't have a natural order to them like numbers?
2. What if the definition of inequality is not transitive - if a < b, b < c BUT a > c? Most sort algorithms assume that sort order is transitive by optimizing away the unnecessary checks.

#### Summary

To surmise, there are three things going on here:

1. The subtractions `(a - b)` or `(b - a)` don't mean anything in isolation
2. The order in which `a` and `b` are passed do not matter.
3. The result of `compare(a, b)` determines the final output.

The confusion lies when the programmer assigns some sort of importance to the parameters `a` and `b`, the order they are passed in, or the result of their values. Thinking of `compare(a, b)` as a black box is a good strategy here.

## Misc

In my research for this; I came across the sorting algorithm that Java uses for its default sorting. It's called [Tims Sort][3] and is a hybridized form of Merge sort. Check it out, its pretty cool.

> A stable, adaptive, iterative mergesort that requires far fewer than n lg(n) comparisons when running on partially sorted arrays - Tims Sort

[1]:https://stackoverflow.com/questions/26107921/what-determines-ascending-or-descending-order-in-comparator-comparable-collect
[2]:http://docs.oracle.com/javase/7/docs/api/java/util/Comparator.html
[3]:http://svn.python.org/projects/python/trunk/Objects/listsort.txt
