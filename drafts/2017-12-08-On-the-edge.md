---
layout: post
title: "On the edge!"
date: 2017-12-09 12:47 -0600
author: "Zeshan Anwar"
---


In another blog [post][Comparator-confusion] we talked about the

```java
Comparator<Integer> ascending = (a,b) -> a - b;
Comparator<Integer> descending = (a, b) -> b - a;
Integer[] numbers = {4, 5, 2, 9, 1};
Arrays.sort(numbers, ascending); // {1, 2, 4, 5, 9}
Arrays.sort(numbers, descending); // {9, 5, 4, 2, 1}
```


### What if the values of approach MIN.VALUE and MAX.VALUE?
How do we compare longs, floats, BigIntegers etc

`a-b` and `b-a` is a terrible hack.

Its a bad abstraction and the worst case of someone being too clever.

As is the case with clever solutions, they catch on and permeate throughout the web. People are inexplicably drawn to these solutions.

You will find several accepted solution on StackOverflow implementing the comparator as a - b. This will work in 98% of scenarios, but why implement a flawed solution to begin with. The 2% of the time it does fail will be extremely hard to debug.










[Comparator-confusion]: https://mzanwar.github.io/2017/09/05/comparator-confusion.html