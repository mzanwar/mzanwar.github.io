---
layout: post
title: ‘Scala lets me do what!'
date: 2018-09-10 00:09 -0500
---



![](https://media.giphy.com/media/SJX3gbZ2dbaEhU92Pu/giphy.gif)



Scala lets you to write custom control structures as library functions. I kid you not, this feature of Scala truly blew my mind. You can’t do this in traditional, non-functional languages. 



As always, a good example to start with:

```scala
  def using[A <: { def close(): Unit }, B](param: A)(f: A => B): B =
    try {
      f(param)
    } finally {
      param.close()
    }

// automatically close the connection once done
using(MongoFactory.getConnection) { conn =>
  MongoFactory.getCollection(conn).save(mongoObj)
}

```

This is really ingenious (at least to me) so I want to break down how it works. First, we look at the method signature. 

- `[A <: { def close(): Unit }, B]` - We are defining two types here `A` and `B`. `A` must define a `close` method.
- `(param: A)(f: A => B)`
  - `(param: A)` - param is of type A which has a .close() method
  - `(f: A => B)` - a function that takes a param A and returns a B
- `f(param)` - Pass param of type A to function f
- `param.close()`- since type A has a `close` method, we call it here.


Another example:

```scala
// Our own if/then/else operator
def when[A](test: Boolean, whenTrue: A, whenFalse: A): A = 
  test match {
    case true  => whenTrue
    case false => whenFalse
  }

scala> when(1 == 2, "foo", "bar")
res13: String = bar

scala> when(1 == 1, "foo", "bar")
res14: String = foo

// cool, but we can do this in other languages too...
// alright, since A can be anything, lets try something fancier...

scala> when(1 == 1, println("foo"), println("bar"))
foo
bar
// wow?! this is really interesting. why did we print both `foo` and `bar`.

// lets change the function signature a little bit
def whenForFunc[A](test: Boolean, whenTrue: => A, whenFalse: => A): A = 
  test match {
    case true  => whenTrue
    case false => whenFalse
  }

scala> whenForFunc(1 == 1, println("foo"), println("bar"))
foo

```

