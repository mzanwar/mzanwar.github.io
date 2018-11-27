---
layout: post
title: Schema Evolution Explained
date: 2018-11-26 13:52 -0600
---


This blog post hopes to illustrate the benefits of schema evolution, and why it may *not* be needed within most types of applications.

## 1. Schema Evolution Explained

In any complex system, a schema change must be handled seamlessly. Schema evolution guarantees that a compatible change in one place *will not* break any other part of a system (graph). Put another way, downstream consumers <u>*do not need to be updated*</u> to handle any compatible changes upstream. This is valuable because it allows us to perturb the graph without worry of breaking something downstream.

There are *three* main schema evolution patterns:

1. <u>Backwards</u> - data encoded with an *older* schema can be read with a <u>newer</u> schema
2. <u>Forwards</u> - data encoded with a *newer* schema can be read with an <u>older</u> schema
3. <u>Full</u> - data encoded with *older or newer* can be read by both <u>older and newer</u> schemas



#### Which pattern to choose?

The evolution pattern is chosen by the relationship between the *producer* and its *consumers*. A handy way to tie the compatibility modes with the *producer-consumer* concept is the following:

- If the *producer* falls behind (‘backwards’) its *consumers*, meaning schema changes are made to *consumers* but not the producer, then we need <u>*Backward*</u> compatibility to ensure seamless operation.
- If the *producer* falls ahead (‘forwards’) of its *consumers*, meaning changes are made to the *producer* but not its *consumers*, then we need <u>*Forward*</u> compatibility to 
- If the *producer and its consumers *have no well-defined relationship, meaning changes are made to both, then we need <u>*Full*</u> compatibility.



To rephrase for emphasis, if we evolve by making compatible changes, we can make *<u>any</u>* compatible change and *guarantee* our system continues to work <u>seamlessly</u>.

### How does evolution provide such a strong guarantee?

Evolution provides such a strong guarantees by supplementing missing fields with default values. Let us examine these *patterns* a little more carefully with some examples:

#### <u>*Backward Evolution*</u>:

We may pick this setting for the following reasons:

- If the *producer* falls behind its *consumers* because changes are made to *consumers*
- *Consumers* are fluid and ever-changing, and *producers* do not change (slow to change)
- New consumers have to read historical data (replay a topic), some of which is written using old schemas



*How to evolve in a backward manner (simplified):*

- <u>Adding new field</u>: Must specify a default value.
- <u>Removing any field</u>: No restriction.
- <u>Mutated name</u>: Essentially two operations: a remove and then an add. Same restrictions apply.
- <u>Mutated type</u>: Not allowed except for [Avro promotion](#AvroPromotion) `int => long` etc.

 ![img](https://documents.lucidchart.com/documents/2b3269c5-a0c4-4ffd-8ebd-b8b5323df4bc/pages/0_0?a=715&x=421&y=242&w=420&h=683&store=1&accept=image%2F*&auth=LCA%20e5e0befbb022ca390dcb9e3ab1597b3a587b4494-ts%3D1537928810)

```scala
// Weather - Backward evolution

// Schema v1
{
    { "name": "temperature", "type": "long" }
}

// Schema v2
// Add a field, humidity, with a default to maintain backward compatibility

{
    { "name": "temperature", "type": "long" },
    { "name": "humidity", "type": "long", "default": 0L }
}

// Schema v3
// Add another field, wind, with a default value to maintain backward compatibility
// Remove temperature field

{
    { "name": "humidity", "type": "long", "default": 0L },
    { "name": "wind", "type": "long", "default": 0L }
}
```



`Producer v1` is producing documents with only `temperature` while `Consumer v3` expects `wind` and `humidity`. Since we have default values in place for both `wind` and `humidity` in`v3`, we are able to continue operation.

Consumers can be upgraded to any evolved schema that is higher than the producers schema, and still function without breaking. Producers can upgrade schemas, but only if they are at the version or below all their consumers. To illustrate from our example, `Producer v1` cannot move to `v2` until `Consumer v1` moves to `v2`. 

In more concrete terms, when the *application code* inside `Consumer v3` tries to something to the effect of `record.getField(“wind”)` , it will return a value of `0L`, which was the default specified in the schema. This trivial explanation will make more sense when we get to the Schema Registry and how it auto-resolves schemas.



#### <u>*Forward Evolution*</u>:

We may pick this setting for the following reasons:

- If the *producer* falls aheads of its *consumers* because schema changes are made to *producers*
- *Producers* are fluid and ever-changing, and *consumers* do not change (slow to change)
- Unchanged (old) *consumers* need the ability to deserialize newly produced documents

*How to evolve in a forward manner (simplified):*

- <u>Adding new field</u>: No restriction, except the obvious (cannot be the same name as another field etc.)
- <u>Removing any field</u>: To delete a field, it must specify a default value.
- <u>Mutated name</u>: Essentially two operations: a remove and then an add. Same restrictions apply.
- <u>Mutated type</u>: Not allowed except for [Avro promotion](#AvroPromotion) but reversed. `long => int`


```scala
// Weather - Forward evolution

// Schema v1
{
    { "name": "temperature", "type": "long" }
}

// Schema v2
// Add field: humidity with default
{
    { "name": "temperature", "type": "long" },
    { "name": "humidity", "type": "long", "default": 0L },
    { "name": "humidity", "type": "long" }
}

// Schema v3
// Add field: wind
{
    { "name": "temperature", "type": "long" },
    { "name": "humidity", "type": "long", "default": 0L },
    { "name": "wind", "type": "long" }
}

// Schema v4
// Remove field: humidity
{
    { "name": "temperature", "type": "long" },
    { "name": "wind", "type": "long" }
}
```

`Producer v4` is producing documents with only `temperature and wind` while `Consumer v3` expects `temperature, wind and humidity`. Since we have default values in place for humidity (0L), we are able to continue operation. `Consumer v1` continues since all it needs is `temperature`.

Everything in this system will continue to work without a hiccup. *Producers* can be *upgraded* to any evolved schema that is higher than its downstream consumers schema. *Consumers* can upgrade schemas, but only if they are at the version or below their parents producers. To illustrate from our example, `Producer v4` cannot move to `v2` until `Consumer v3` moves to `v2`. 

In more concrete terms, when the *application code* inside `Consumer v3` tries to do something of the sort of `record.getField(“humidity”)` it will return a value of `0L`. Again, this seemingly trivial explanation will make more sense when we get to the Schema Registry and how it auto-resolves schemas.



#### *<u>Full Evolution:</u>*

We may pick this setting for the following reasons:

- If the *producer* falls behind its *consumers* and  *consumers* fall behind producers
- *Consumers* are fluid and ever-changing, and *producers* are also fluid and evolving
- We want the ability for old and new consumers to deserialize old and new data.



*How to evolve (simplified):*

- <u>Adding new field</u>: Must specify a default value.
- <u>Removing any field</u>: Field must have a default value.
- <u>Mutated name</u>: Essentially two operations a remove with an add. Same restrictions apply.
- <u>Mutated type</u>: Not allowed (even [Avro promotion](#AvroPromotion)) The only type change allowed is `string <=> bytes`

 ![img](https://documents.lucidchart.com/documents/2b3269c5-a0c4-4ffd-8ebd-b8b5323df4bc/pages/0_0?a=748&x=421&y=249&w=420&h=683&store=1&accept=image%2F*&auth=LCA%2012394970b9487e02d4a2eb1a4ef4c77c6db8b47e-ts%3D1537928810)

*Producers* can be *upgraded* to any evolved schema on the schema timeline. *Consumers* can also be upgraded to any schema on the timeline. 



### Summary:

The important takeaway here is that the value in evolution is only realized when we have a *<u>mismatch</u>* in *producer* and *consumer* schema versions. This is by design. If we were to update all the affected  *producers/consumers* every time we made a schema change, then we wouldn’t really need evolution, nor would we be utilizing its value. Or, put in a different way, if both producer and consumer schema were *<u>always</u>* forced to be the same, we wouldn’t really have evolution.

The *backbone* of evolution is the ability to replace a <u>missing</u> field with a default value. So far we’ve assumed that the priority of our system is to continue operating even if fields are missing. What if this is not what we want? Worse yet, what if by ‘papering’ over a missing field by replacing it with a default value, we run the risk of *incorrect computations* and *polluted streams*.

An important question to to ask is: *Where, in the application, do we actually need default values?*
