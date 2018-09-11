---
layout: post
title: ‘Scala: Partially Applied Functions‘
date: 2018-09-09 20:48 -0500
---

```scala
val plus = (a: Int) => (b: Int) => a + b
// can also be written as, but can't be partially applied
// val plus = (a: Int)(b: Int) => a + b
val plus3 = plus(3)

plus3(4) // = 7
plus(2)(8) // = 10


/* using def the syntax is slightly different */

def multiply(a: Int)(b: Int): Int = a * b
val multiplyBy3 = multiply(3)(_) // need the extra _

multiplyBy3(15) // = 45
```

