# Ruby Rabbit RPC Client

Playing with Rabbit RPC client


## ConcurrentClient

Based on concurrent-ruby Map + IVar

```
Warming up --------------------------------------
          new-client    11.000  i/100ms
     existing-client   149.000  i/100ms
Calculating -------------------------------------
          new-client    126.560  (± 9.5%) i/s -    627.000  in   5.001786s
     existing-client    236.695k (±15.0%) i/s -      1.134M in   4.993230s

Comparison:
     existing-client:   236695.1 i/s
          new-client:      126.6 i/s - 1870.21x  slower
```

### Stress test

*Client per thread:*
```
Runtime:   0.303732   0.198723   0.502455 (  0.415927)

Latency Stats
 50.000%          357
 75.000%          367
 90.000%          380
 99.000%          383
 99.900%          384
 99.990%          384
 99.999%          384
100.000%          384
```

*Same client:*

```
Runtime:   0.024754   0.010672   0.035426 (  0.031249)

Latency Stats
 50.000%           14
 75.000%           15
 90.000%           15
 99.000%           16
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
