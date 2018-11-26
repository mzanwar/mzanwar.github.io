---
layout: post
title: Avro Schema Evolution
date: 2018-11-26 13:52 -0600
---

# Confluent Schema Registry

**Summary**: 

1. Auto-schema resolution **breaks** evolution safety-guarantees.
2. Do we really need evolution safety-guarantees?

I highly recommend you read the rest of this post to understand why.

This document hopes to illustrate the benefits of schema evolution, and why they are **not** needed within most types of applications. Furthermore, it highlights why the **<u>auto-schema selection</u>** nullifies evolution safety-guarantees, and a potential ways to mitigate against such a thing. It ends with some non-intuitive quirks of the Schema Registry that we must all be cognizant of. If you read only one section, read about these quirks.

## 1. Schema Evolution Explained

We must be able to handle schema changes seamlessly. Schema evolution guarantees that a compatible change in one place **will not** break any other part of a graph. Put another way, downstream consumers <u>**do not need to be updated**</u> to handle any compatible changes upstream. This is valuable because it allows us to perturb the graph without worry of breaking something downstream.

> There are **three** main schema evolution patterns:
>
> 1. <u>Backwards</u> - data encoded with an **older** schema can be read with a <u>newer</u> schema
> 2. <u>Forwards</u> - data encoded with a **newer** schema can be read with an <u>older</u> schema
> 3. <u>Full</u> - data encoded with **older or newer** can be read by both <u>older and newer</u> schemas



#### Which pattern to choose?

The evolution pattern is chosen by the relationship between the **producer** and its **consumers**. A handy way to tie the compatibility modes with the **producer-consumer** concept is the following:

- If the **producer** falls behind (‘backwards’) its **consumers**, meaning schema changes are made to **consumers** but not the producer, then we need <u>**Backward**</u> compatibility to ensure seamless operation.
- If the **producer** falls ahead (‘forwards’) of its **consumers**, meaning changes are made to the **producer** but not its **consumers**, then we need <u>**Forward**</u> compatibility to 
- If the **producer and its consumers **have no well-defined relationship, meaning changes are made to both, then we need <u>**Full**</u> compatibility.



To rephrase for emphasis, if we evolve by making compatible changes, we can make **<u>any</u>** compatible change and **guarantee** our system continues to work <u>seamlessly</u>.

### How does evolution provide such a strong guarantee?

Evolution provides such a strong guarantees by supplementing missing fields with default values. Let us examine these **patterns** a little more carefully with some examples:

#### <u>**Backward Evolution**</u>:

We may pick this setting for the following reasons:

- If the **producer** falls behind its **consumers** because changes are made to **consumers**
- **Consumers** are fluid and ever-changing, and **producers** do not change (slow to change)
- New consumers have to read historical data (replay a topic), some of which is written using old schemas



**How to evolve in a backward manner (simplified):**

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

In more concrete terms, when the **application code** inside `Consumer v3` tries to something to the effect of `record.getField(“wind”)` , it will return a value of `0L`, which was the default specified in the schema. This trivial explanation will make more sense when we get to the Schema Registry and how it auto-resolves schemas.



#### <u>**Forward Evolution**</u>:

We may pick this setting for the following reasons:

- If the **producer** falls aheads of its **consumers** because schema changes are made to **producers**
- **Producers** are fluid and ever-changing, and **consumers** do not change (slow to change)
- Unchanged (old) **consumers** need the ability to deserialize newly produced documents

**How to evolve in a forward manner (simplified):**

- <u>Adding new field</u>: No restriction, except the obvious (cannot be the same name as another field etc.)
- <u>Removing any field</u>: To delete a field, it must specify a default value.
- <u>Mutated name</u>: Essentially two operations: a remove and then an add. Same restrictions apply.
- <u>Mutated type</u>: Not allowed except for [Avro promotion](#AvroPromotion) but reversed. `long => int`

![Blank Diagram](/Users/zeshan.anwar/Desktop/ForwardEvolution.png)

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

Everything in this system will continue to work without a hiccup. **Producers** can be **upgraded** to any evolved schema that is higher than its downstream consumers schema. **Consumers** can upgrade schemas, but only if they are at the version or below their parents producers. To illustrate from our example, `Producer v4` cannot move to `v2` until `Consumer v3` moves to `v2`. 

In more concrete terms, when the **application code** inside `Consumer v3` tries to do something of the sort of `record.getField(“humidity”)` it will return a value of `0L`. Again, this seemingly trivial explanation will make more sense when we get to the Schema Registry and how it auto-resolves schemas.



#### **<u>Full Evolution:</u>**

We may pick this setting for the following reasons:

- If the **producer** falls behind its **consumers** and  **consumers** fall behind producers
- **Consumers** are fluid and ever-changing, and **producers** are also fluid and evolving
- We want the ability for old and new consumers to deserialize old and new data.



**How to evolve (simplified):**

- <u>Adding new field</u>: Must specify a default value.
- <u>Removing any field</u>: Field must have a default value.
- <u>Mutated name</u>: Essentially two operations a remove with an add. Same restrictions apply.
- <u>Mutated type</u>: Not allowed (even [Avro promotion](#AvroPromotion)) The only type change allowed is `string <=> bytes`

 ![img](https://documents.lucidchart.com/documents/2b3269c5-a0c4-4ffd-8ebd-b8b5323df4bc/pages/0_0?a=748&x=421&y=249&w=420&h=683&store=1&accept=image%2F*&auth=LCA%2012394970b9487e02d4a2eb1a4ef4c77c6db8b47e-ts%3D1537928810)

**Producers** can be **upgraded** to any evolved schema on the schema timeline. **Consumers** can also be upgraded to any schema on the timeline. 



### Summary:

The important takeaway here is that the value in evolution is only realized when we have a **<u>mismatch</u>** in **producer** and **consumer** schema versions. This is by design. If we were to update all the affected  **producers/consumers** every time we made a schema change, then we wouldn’t really need evolution, nor would we be utilizing its value. Or, put in a different way, if both producer and consumer schema were **<u>always</u>** forced to be the same, we wouldn’t really have evolution.



## 2. Schema Registry auto-schema resolution breaks evolution

The Schema Registry provides **consumers** the ability to dynamically resolve the correct schema at the time of deserialization. In other words, the schema used to write a document, is also the **exact same schema** used to read it.  This is normally not the case in typical circumstances. This means the moment we introduce a schema change at the **<u>producer</u>** level, we force all downstream <u>**consumers**</u> to **dynamically** pick up that change. This may seem like a nifty little feature, and it is, but it also brings with it some interesting drawbacks. Since the SR now forces both producer schema and consumer schema versions to be the **exact same**, we have some interesting **side-effects**:



1. **Evolution guarantees are nullified** - The safety value provided by evolution is significantly diminished. With schema evolution, we could guarantee that a compatible change would not break existing infrastructure. **We cannot guarantee that anymore**. That is, a compatible change <u>**can**</u> and <u>**will**</u> break existing infrastructure. From our previous example with ‘Forward’ evolution, when our `Producer` evolved from `v1` to `v4`, we could guarantee that the downstream consumers `Consumer v1` and `Consumer v3` would continue operating without hassle. With SR in the mix, when our `Producer` evolves from `v1` to `v4`, our consumers also evolve from `v1` to `v4`. More concretely, when the **application code** inside `Consumer v3 (now v4)` tries to do a `record.getField(“humidity”)` it will break because `v4` does not have a **default** value defined for `humidity`.
2. **Default values can only be null (cannot be anything else)** - This is really interesting. Why is this? The Avro documentation states that a default value is used **only during consumption (read)** to fill in for when a field does not exist. Since a producer is using the **exact same schema** a consumer is, a missing field at the producer gets published with a ’null’ value into the stream. Producers don’t apply the default in this case. This means a consumer never really sees a **missing field** since it is now set to a value of ’null’. This also means that types needs to be of union [type, “null”], otherwise the producer will fail on missing values.

```java
// weatherSchema
{
    { "name": "temperature", "type": "long" },
    { "name": "humidity", "type": "long", "default":0L }
}

val weatherRecord = new GenericData.Record(weatherSchema)
weatherRecord.put("temperature", 100)
weatherRecord.put("humidity", 10)
producer.send(weatherRecord)

/* weatherRecord = {
    "temperature": 100,
    "humidity": 10
}
*/
// Everything looks in order. 
    
    
    
// Now let us omit a field intentionally
val weatherMissing = new GenericData.Record(weatherSchema)
weatherMissing.put("temperature", 100)
producer.send(weatherMissing)

/*`Exception in thread "main" org.apache.kafka.common.errors.SerializationException: Error serializing Avro message
Caused by: java.lang.NullPointerException: null of long in field humidity of schemaregistry.weather` */
```

If we intentionally omit adding a value for humidity, we fail because our type of `long` does not match `null`. We will need change our type for the missing field from `"long"` to `["null", "long"]`. KSQL does this by default.

Let’s try that again, but with the correct union type.

```scala
// weatherSchemaWithUnion - note union type ["null", "long"]
{
    { "name": "temperature", "type": "long" },
    { "name": "humidity", "type": ["null", "long"], "default":0L }
}

val weatherRecord = new GenericData.Record(weatherSchemaWithUnion)
weatherRecord.put("temperature", 100)
producer.send(weatherRecord)
/* {
    "temperature": 100,
    "humidity": null // note how this is null and NOT 0L
} */
```

Notice how the value of humidity is `null` and not `0L` which was the default value specified in the schema.



#### Potential ways to solve:

1. Forcibly disable auto-resolution by letting each consumer lookup its own version of the schema manually using topic name + version. This means not using the `id`  to lookup the schema. This way every consumer is tied to a single version of a schema. A little quirk: SR stores schemas using an `id` which is an atomically increasing, topic-agnostic number, assigned at registration time. This `id`  is also used for **automatic** schema lookup. They provide a REST API endpoint to lookup a schema with topic name + version, but this needs to be done manually.
2. Only use SR for validation but handle all schema changes manually.



## 3.  Are evolution safety-guarantees really what we want?

The **backbone** of evolution is the ability to replace a <u>missing</u> field with a default value. So far we’ve assumed that the priority of our system is to continue operating even if fields are missing. What if this is not what we want? Worse yet, what if by ‘papering’ over a missing field by replacing it with a default value, we run the risk of **incorrect computations** and **polluted streams**.

An important question to answer: **Where, in the application, do we actually need default values?**

**<u>Definitions:</u>**

**Used** - Used inside the application in any capacity

**Required** - Required by the final document

- **Input Node (Specific Record, schema is compiled in, Emodb -> Input -> Rule/Joiner/Filter):** 

  - <u>Unused, not required fields</u> - We have fields that are not used by the application, and do not need to show up in the final document. We filter them out at the input. The schema does not define them. (~ fields)

  - <u><span style="color:green">Unused, occasionally missing fields</span></u>: These are optional fields that exist in some documents and not in others. These are fields that tag along and need to show up in the final document. These need a <u>**default**</u> value in the transformer.

  - <u>Unused, required fields</u> - We have fields that are not used by the application, but need to show up in the final document. These **cannot** have a default defined. We need to fail-fast when these fields disappear.

  - <u>Used, not required fields</u> - We shouldn’t have any of these.

  - <u><span style="color:green">Used, occasionally missing fields</span></u>: These fields will be used inside the application in a rule/filter/join capacity. These need to be evaluated on a case to case basis. Almost always, we should throw an exception if they are missing, but we may have cases that will require us to specify a default value (0, “” etc.) Newly added and removed fields fall into this category.

  - <u>Used, required fields</u> - These are used within the application and are required. These cannot have a **default** value. We need to fail-fast when these fields disappear.

    |      Input Node      |                   Used                   |                  Unused                  |
    | :------------------: | :--------------------------------------: | :--------------------------------------: |
    |     Not required     |     <span style="color:red">X</span>     | <span style="color:green">Default</span> |
    | Occasionally missing | <span style="color:green">Default</span> |     <span style="color:red">X</span>     |
    |       Required       |     <span style="color:red">X</span>     |     <span style="color:red">X</span>     |

- **the application-the application nodes (Generic Record, KSQL, Rule -> Joiner, Filter -> Joiner):**

  - <u>Unused, not required fields</u> - These are extraneous fields that accompany the output of another the application node (Rule, Filter etc.) These accompany used, required fields, thus **cannot** be missing nor set to a default value. **Must fail-fast**.

  - <u>Unused, occasionally missing fields</u>: We shouldn’t have occasionally missing fields for the application-the application nodes. **Fail-fast if this happens.**

  - <u>Unused, required fields</u> - We have fields that are not used in a filter/rule/join capacity but need to show up in the output document. These **cannot** have a default defined. We need to fail-fast when these fields disappear.

  - <u>Used, not required fields</u> - We shouldn’t have any of these.

  - <u>Used, occasionally missing fields</u>: These fields will be used inside the application in a rule/filter/join capacity. We shall never have these for the application-the application nodes. **Fail-fast if this happens.**

  - <u>Used, required fields</u> - These are used within the application and are required. These **cannot** have a **default** value. We need to fail-fast when these fields disappear.

    | the application-the application Node | Used                               | Unused                           |
    | ------------------------------------ | ---------------------------------- | -------------------------------- |
    | Not required                         | <span style="color:red">N/A</span> | <span style="color:red">X</span> |
    | Occasionally missing                 | <span style="color:red">X</span>   | <span style="color:red">X</span> |
    | Required                             | <span style="color:red">X</span>   | <span style="color:red">X</span> |



Th interesting tidbit here is we **<u>never want</u>** default values to replace missing fields for the application to the application nodes. We always want to fail fast if we’re missing a value or a field. The only place where the application needs support for default values is at the Input node for **<span style="color:green">Unused, occasionally missing fields</span>**, and **<span style="color:green">Used, occasionally missing fields</span>**. We can evolve input node schemas in a compatible way, but this will be a manual process since they are compiled-in and not part of the Schema Registry auto-select process. We can leverage SR to validate.

Since schema evolution is backed by default values, we don’t actually need evolution inside of the application. We always want to fail-fast. A good example to illustrate this is a **fat-rule**. A **fat-rule** computes several similar fields and <u>batches</u> them together in its output. A fat-rule is a good example because some of its extraneous fields **may not be used** by all the downstream consumers.  An example:

```scala
// example fat-rule for avgRating; it also emits the numOfReviews and sumOfRatings
{
    "avgRating": 4.53,
    "numOfReviews": 100,
    "sumOfRatings": 453
}
```

Say we want to deprecate all unused fields. We start by looking at our **fat-rules** (because they be fat) to determine if all the emitted fields are being used downstream. How do we determine if a field, say `sumOfRating`, is unused by all its downstream consumers? **We cannot determine this without some serious overhead!** If we ever do remove it, accidentally or intentionally, a downstream consumer of that field should **break** immediately, and **<u>not</u>** continue running with a default value. In other words, we **never** want an internal `the application - the application` to compute/join/filter on a default value. There should **never** be a sane use-case for default values within the application. <u>An interesting axiom of the application: if we add a new a field and start publishing, we cannot remove it.</u> To handle a removal, we need to build a separate branch.



> **Fat-rules** should generally be avoided. Batching together computations might seem to be more efficient but determining who uses a specific internal field may be very difficult. With **single-field-rules** the graph definition is sufficient to determine use. We can always run multiple **single-field-rules** on a single node (EC2 instance) for cost-saving.



#### What value, then, does evolution provide the application?

We can leverage evolution restraints to catch a lot of 

Are the all the restrictions that evolution posits, the same restrictions that we want it the application? **<u>No</u>**, but there is a significant overlap of concerns. Also remember SR provides an automated validation check against a schema, which is tremendously valuable.

We need a list of **<u>additional requirements</u>** that our schema must adhere to when evolving. <u>If our change does not pass this test, we **cannot** evolve our schema, and must **branch** to handle that change.</u>

|                   Additional Requirements                    | Why?                                                         |
| :----------------------------------------------------------: | ------------------------------------------------------------ |
|      Disallow removal any field - required or optional       | It is difficult to determine which downstream node consumes that field. We don’t want to be the ones tracing through the application to determine this. We will  disallow this here. If a field needs to be removed, we branch, and migrate downstream nodes to the new branch. |
| Disallow adding an optional field - a field with a default value. | SR will forcibly disallow a removal of a required field. If we add a field, it has to be a required field. A required field cannot be removed because it’ll fail the SR compatibility check. |
|       Disallow adding a union type with ‘null’ in set.       | Protect ourselves from polluted streams. We want to fail-fast at the producer if a field goes missing. |
|               Disallow mutation of field name.               | This is analogous to removing a field. Same reason.          |
|   Disallow mutation of field type (except Avro promotion)    | This is analogous to removing a field. Same reason.          |



Let us compare these with the three **transitive** evolution patterns:

|                   Requirements                   |                  FULL                  |               BACKWARDS                |                FORWARDS                |
| :----------------------------------------------: | :------------------------------------: | :------------------------------------: | :------------------------------------: |
| Allows adding a required field (without default) |    <span style="color:red">X</span>    |    <span style="color:red">X</span>    |   <span style="color:green">✔</span>   |
|              Allows type promotion               |    <span style="color:red">X</span>    |   <span style="color:green">✔</span>   | <span style="color:green">✔</span> ^1^ |
|        Prevents removing a required field        | <span style="color:green">✔</span> ^2^ |    <span style="color:red">X</span>    |   <span style="color:green">✔</span>   |
|   Prevents adding an optional field (default)    |    <span style="color:red">X</span>    |    <span style="color:red">X</span>    |    <span style="color:red">X</span>    |
|    Prevents mutating name for required fields    | <span style="color:green">✔</span> ^2^ | <span style="color:green">✔</span> ^2^ |   <span style="color:green">✔</span>   |
|    Prevents mutating type for required fields    | <span style="color:green">✔</span> ^2^ | <span style="color:green">✔</span> ^2^ |   <span style="color:green">✔</span>   |
|   Cannot add a union type with ‘null’ in set.    |    <span style="color:red">X</span>    |    <span style="color:red">X</span>    |    <span style="color:red">X</span>    |



To add, **FULL_TRANSITIVE** does not allow Avro type promotions, and you can only add a field with a default value ^2^. This means we can’t add ‘required' fields. **BACKWARD_TRANSITIVE** also only allow us to add fields with default values but allows Avro promotion in the normal sense `int -> long -> double`.**FORWARD_TRANSITIVE** **allows** us to add fields without default values and allows Avro promotion in the backward sense^1^ `long -> int`.



What **FORWARD_TRANSITIVE** fails to catch is the addition/removal of an optional field, and a union type containing [’null’]. We can supplement that by requiring an additional pair of criteria:

1. **Cannot add optional fields with a default value**. This ensures once a field is added, it cannot be removed.
2. **Union types cannot contain ’null’**. We fail-fast (at producer) and prevent pollution of streams.



> **Protect pollution of streams**: We need to define all our fields without a union type containing [“null”]. Thus, a missing field will break at the producer side. Otherwise we risk passing a null value into the stream and to the consumer. We want to protect our streams from being polluted, by failing if there is missing data.



**<u>'Can the mutation be done in the same stream' matrix:</u>**

By ‘node requires change’ we mean the application code in the nodes uses the field. A checkmark indicates that the change can be made in the same stream, and a cross indicates it cannot. Note that determining whether a node required a change is **<u>HARD</u>**, especially if we have several downstream consumer. We don’t want to do this check.

|              Forward_Transitive               |     Is valid schema evolution?     | Consumer that requires it does not break? |
| :-------------------------------------------: | :--------------------------------: | :---------------------------------------: |
|            Add a field w/o default            | <span style="color:green">✔</span> |    <span style="color:green">✔</span>     |
|           Add a field with default            | <span style="color:green">✔</span> |    <span style="color:green">✔</span>     |
|          Remove a field w/o default           |  <span style="color:red">X</span>  |     <span style="color:red">X</span>      |
|          Remove a field with default          | <span style="color:green">✔</span> |     <span style="color:red">X</span>      |
|       Mutate a field name with default        | <span style="color:green">✔</span> |     <span style="color:red">X</span>      |
|        Mutate a field name w/o default        |  <span style="color:red">X</span>  |     <span style="color:red">X</span>      |
|       Mutate a field type with default        |  <span style="color:red">X</span>  |     <span style="color:red">X</span>      |
|        Mutate a field type w/o default        |  <span style="color:red">X</span>  |     <span style="color:red">X</span>      |
| Mutate type valid avro promotion with default | <span style="color:green">✔</span> |    <span style="color:green">✔</span>     |
| Mutate type valid avro promotion w/o default  | <span style="color:green">✔</span> |    <span style="color:green">✔</span>     |



## 4. Quirks - things to be aware of when using the SR:

1. **If a schema is removed (destroyed), we will lose the capability to read documents encoded with that schema.**
   - Any documents encoded with that schema will be lost, unless the schema is restored at the correct `id` path. 
   - What if a schema is deleted after a consumer has already cached it? Restarting that consumer will break nonetheless.
   - See 3.
2. **Default values are only ever null, even with a default specified**.
   - Also, type must be a union [“null”, type]
3. **Deleting a schema doesn’t really remove it from the Schema Registry**
   - It can still be looked up (by `id`) and used by consumers. Deleting is useful when you want to remove a schema to pass a compatibility check.
4. **Automatic Schema lookup is based on `id`, which is agnostic of topic or version.**
   - This is highly problematic. If we ever need to restore our Schema Registry, even if we have all the schemas, they must be registered in the exact same order every time, otherwise we risk losing the ability to read old data. SR does provide a REST API to lookup using topic + version but this has to be done manually. I believe this was an optimization done to save space by storing the `id` instead of `topic_name` and `version` with each record.  
5. **BACKWARD, FORWARD and FULL compatibility levels can essentially be reduced to NONE** 
   - The default check is **only** against the <u>last registered schema</u>. You can easily apply a set of deltas to violate compatibility. If needed, always use a **backwards_transitive, forwards_transitive or full_transitive**.
6. **Global compatibility and topic-specific compatibility can be changed on the fly**
   - An actor (nefarious or accidentally) can pollute a schema evolution stream by turning compatibility off, or flipping it and registering an incompatible schema.
7. **Schema Registry won’t auto-resolve to an evolved schema, even when one exists under the topic**
   - If a topic is set with transitive backward compatibility (best case scenario), a qualified compatible schema that **can** read the record will exist, but SR will fail to pull it down because it can’t find the **exact** schema (`id`) that wrote the record.

## 5. Potential PRs to SR (in increasing order of difficulty):

1. Update their REST API Error message for compatibility - They haven’t updated their log messages when setting compatibility levels.
2. Default state should be **backward_transitive**, not **backward**.
3. Have a **strict** mode, where compatibility cannot be changed once defined at creation.
4. When changing compatibility, check to see if all/latest existing schema adhere to the compatibility.
5. With **strict** mode and transitive compatibility enabled, if schema `id` not found, pick up latest compatible schema.
6. Producer (GenericRecord) should **inject default Avro value** (instead of null) when value does not exist.
7. Add flag to enable automatic lookup of schema using `topic_name` + `version`, instead of the arbitrary `id`





> ### AvroPromotion
>
> The writer's schema may be promoted to the reader's as follows:
>
> - int is promotable to long, float, or double
> - long is promotable to float or double
> - float is promotable to double
> - string is promotable to bytes
> - bytes is promotable to string