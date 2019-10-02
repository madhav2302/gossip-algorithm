# GOSSIP

### Group Members
1.   Madhav Sodhani       :     1988-9109 
1.   Vaibhav Mohan Sahay  :     5454-1830

--- 

### Steps to run the project:
   `mix escript.build`
   `./my_program <number of nodes> <topology> <algorithm> <failure_percentage>`


### What is working?   

For both gossip and push-sum algorithm, all 6 topologies i.e. Full, Line, Random 2D, 3D torus, Honeycomb and Random Honeycomb networkds are working.
 
---

### Sample Output

Run-1

```text
Vaibhavs-MacBook-Air:proj2Master vaibhav$ ./my_program 500 line push-sum 10
Neighbours Initialized, Now Starting Gossip/PushSum
Convergence Time is 58 with workers ran 23 with percentage 1.4000000000000001
```

--- 


