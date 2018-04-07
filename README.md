# Ruby Rabbit RPC Client

Playing with Rabbit RPC client


## ConcurrentClient

- concurrent: uses concurrent-ruby map + ivar
- one rabbitmq connection
- one rabbit reply consumer

```
Warming up --------------------------------------
          new-client   158.000  i/100ms
     existing-client   158.000  i/100ms
Calculating -------------------------------------
          new-client      1.544k (± 4.0%) i/s -      7.742k in   5.023626s
     existing-client    245.078k (±16.1%) i/s -      1.170M in   4.994396s

Comparison:
     existing-client:   245077.7 i/s
          new-client:     1543.6 i/s - 158.77x  slower
```

### Stress test

*Client per thread:*
```
Runtime:   0.034071   0.012984   0.047055 (  0.041922)

Latency Stats
 50.000%           19
 75.000%           20
 90.000%           20
 99.000%           21
 99.900%           21
 99.990%           21
 99.999%           21
100.000%           21
```

*Same client:*

```
Runtime:   0.023474   0.009739   0.033213 (  0.029422)

Latency Stats
 50.000%           15
 75.000%           16
 90.000%           16
 99.000%           17
 99.900%           17
 99.990%           17
 99.999%           17
100.000%           17
````

## SimpleClient

Copied from the rabbitmq guide, uses locks

```
Warming up --------------------------------------
          new-client    11.000  i/100ms
     existing-client   134.000  i/100ms
Calculating -------------------------------------
          new-client    117.800  (± 4.2%) i/s -    594.000  in   5.050452s
     existing-client    209.798k (±18.7%) i/s -    987.312k in   4.992424s

Comparison:
     existing-client:   209798.1 i/s
          new-client:      117.8 i/s - 1780.97x  slower
```

### Stress test

*Client per thread:*
```
Runtime:   0.271452   0.183225   0.454677 (  0.369647)

Latency Stats
 50.000%          319
 75.000%          334
 90.000%          343
 99.000%          353
 99.900%          354
 99.990%          354
 99.999%          354
100.000%          354
```


*Same client:*
never finishes.
