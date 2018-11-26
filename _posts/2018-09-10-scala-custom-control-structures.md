---
layout: post
title: "Scala lets me do that!"
date: 2018-09-10 00:09 -0500
---



![](https://media.giphy.com/media/SJX3gbZ2dbaEhU92Pu/giphy.gif)



I kid you not, this feature of Scala totally blew my mind and I had to write a little post about it. I come from a non-functional, functions need to be treated differently from variables, background so thinking like this was really mind-mending.

Scala lets you to write custom control-flow structures as library functions. Wait... what does that mean? You can write your own `while`, `if`, `for`, `onlyOnceIf` control-flow mechanisms.  You can’t do this in traditional, non-functional languages.


A really good example I came across:

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


Another example is that of the ternary operator. We can implement our own control logic to mimic the behaviour.

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

```

I know what you're thinking - gee, Zeshan, we can do this in almost any other language. And you're correct, except for one minor case. We can also pass functions as parameters. Time to get really fancy:

```scala
scala> when(1 == 1, println("foo"), println("bar"))
foo
bar
// Wait, what?! Why did it run both functions?
// This is really interesting. Why did we print both `foo` and `bar`...?

// Hmm... change the function signature a little bit
def whenForFunc[A](test: Boolean, whenTrue: => A, whenFalse: => A): A =
  test match {
    case true  => whenTrue
    case false => whenFalse
  }

scala> whenForFunc(1 == 1, println("foo"), println("bar"))
foo
```

Apparently `whenTrue: A` is different from `whenTrue: A` when the parameter is a function. This is really intriguing I'm planning on devoting a whole post on it. Nevertheless, I hope you can appreciate the power of writing your own custom control structures as library functions.