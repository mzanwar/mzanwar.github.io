---
layout: post
title: 'Scala: Custom control structures'
date: 2018-09-10 00:09 -0500
---

### Custom control structures

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





1. `def using[A <: { def close(): Unit }, B](param: A)(f: A => B): B`
   - `[A <: { def close(): Unit }, B]` - A & B are two types, A can be any class that has `close(): Unit` defined, B can be any class
   - `(param: A)` - param is of type A which has a .close() method
   - `(f: A => B)` - a function that takes an A and returns a B

