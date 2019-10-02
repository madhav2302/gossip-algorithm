# GOSSIP

### Group Members
1.   Madhav Sodhani       :     1988-9109 
1.   Vaibhav Mohan Sahay  :     5454-1830

--- 

### Steps to run the project:
   `mix escript.build`
   `./my_program <number of nodes> <topology> <algorithm>`


### What is working?   

For both gossip and push-sum algorithm, all 6 topologies i.e. Full, Line, Random 2D, 3D torus, Honeycomb and Random Honeycomb networkds are working.
 
---

### Sample Output

Run-1

```text
Vaibhavs-MacBook-Air:proj2Master vaibhav$ ./my_program 500 line push-sum
Convergence Time is 658 with workers ran 320 with percentage 37.6
```


--- 
#### Largest Network

| Largest Network  | Gossip | PushSum |
|------------------|--------|---------|
| Full             | 15,000 | 1,500   |
| Line             | 10,000 | 1,000   |
| Rand2D           | 10,000 | 3,000   |
| 3D-Torus         | 20,000 | 5,000   |
| Honeycomb        | 20,000 | 10,000  |
| Random Honeycomb | 15,000 | 20,000  |


