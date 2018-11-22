---
layout: post
title: 'Scala: by-name parameters'
date: 2018-09-11 11:47 -0500
categories: scala 
---

In Scala, functions are first-class citizens. This is just a fancy way of saying functions (blocks of code) and variables (data) are treated the same way. This leads to interesting insights but can also be confusing for newcomers to Functional Programming.

```scala
// 1. data
val data = 5

// 2. block of code - hmm, what can I do with this?
val blockOfCode = {
  println("I am a block of code, I run once, when I am evaluated")
  util.Random.nextInt(100)
}

// 3. function - interesting... I wonder how this works
val function = () => {
  val rand = util.Random.nextInt(100)
  println(s"I am a function, I run every time I am called. Rand number: $rand")
  rand
}

// 4. def function - interesting... I wonder how this works
def method = {
  val rand = util.Random.nextInt(100)
  println(s"I am a function, I run every time I am called. Rand number: $rand")
  rand
}
```



```scala
val a = data // Type: Int, 5
val b = blockOfCode // Type: Int
val c = function // () => Int
val d = method() // Type: Int, 53


List(a, a, a, a) // List[Int] = List(5, 5, 5, 5)
List(b, b, b, b) // List[Int] = List(37, 37, 37, 37)
List(c(), c(), c() ,c()) 
/*
I am a function, I run every time I am called
I am a function, I run every time I am called
I am a function, I run every time I am called
I am a function, I run every time I am called
List[Int] = List(34, 55, 54, 11) 
*/
List(d, d, d, d) // List[Int] = List(53, 53, 53, 53)
```





>```scala
>
>```
>
>| Name          | Type        |         |
>| ------------- | ----------- | ------- |
>| `data`        | `Int`       | Trivial |
>| `blockOfCode` | `Int`       |         |
>| `function`    | `() => Int` |         |
>| `function()`  | `Int`       |         |
>
>



### Now the tricky part!

Take a look at this test function:



```scala
def test[A](paramUsed: A, paramNotUsed: A): A = {
  println("Start test")
  val result = paramUsed
  println("End Test")
  result
}

// takes in two params of type A, doesn't matter what A is
// Notice that only paramUsed is being executed on line 3.
// paramNotUsed is not. This is important


// Let us try a simple example with integers
println("Starting code execution")
test(1, 2)


val function = () => {
  val rand = util.Random.nextInt(100)
  println(s"I am a function. I run every time I am called. Rand number: $rand")
  rand
}

println("Starting code execution")
test(println(123), println(123)) 

```



```scala
def test[A](codeA: => A, codeB: => A): A = {
  println("Start test")
  codeA
}

```



- Confusion between => and () =>