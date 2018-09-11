---
layout: post
title: 'Scala: Custom control structures'
date: 2018-09-10 00:09 -0500
---

### Writing your own control structures



Functional Programming





> Differences between parameters :
>
> 1. A - same type
> 2. => A - are the same type
> 3. () => A
> 4. \[A, B\](B) => A

```scala
object Control {

  def using[A <: { def close(): Unit }, B](param: A)(f: A => B): B =
    try {
      f(param)
    } finally {
      param.close()
    }

}


// Application

import Control._

using(MongoFactory.getConnection) { conn =>
  MongoFactory.getCollection(conn).save(mongoObj)
}

```



Another example:

```scala
// Our own if/then/else 
def when[A](test: Boolean, whenTrue: A, whenFalse: A): A = 
  test match {
    case true  => whenTrue
    case false => whenFalse
  }

scala> when(1 == 2, "foo", "bar")
res13: String = bar

scala> when(1 == 1, "foo", "bar")
res14: String = foo

// Ok so far, but...

scala> when(1 == 1, println("foo"), println("bar"))
foo
bar

scala> // hmmm

def when[A](test: Boolean, whenTrue: => A, whenFalse: => A): A = 
  test match {
    case true  => whenTrue
    case false => whenFalse
  }
```





1. `def using[A <: { def close(): Unit }, B](param: A)(f: A => B): B`
   - `[A <: { def close(): Unit }, B]` - A & B are two types, A can be any class that has `close(): Unit` defined, B can be any class
   - `(param: A)` - param is of type A which has a .close() method
   - `(f: A => B)` - a function that takes an A and returns a B

