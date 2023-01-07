# Simulation Tasks

1. Simulation using one radar object does not produce correct results
2. Simulation using simulate_sweeps works fine - see pat sim basic 2tgt
3. when using separate radar objects, same issue occurs as in (1). This is 
strange as the single one should work the same as (2). Must be some other
error introduced in the 2 radar programs.

Continue from the above notes

### Programs to use are:

1. pat sim basic 2tgt 2rdr - has separate objects for left and right sides
2. pat multi targ full - has single objects
3. pat sim basic 2tgt - the golden measure which works for single radar, multi target
4. also need to edit the associated simulation helpers in the matlab lib folder