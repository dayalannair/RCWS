# Current state directory

This directory holds all of the latest/current files being tested/designed/used. This includes simulation (sm),
real data (rd), etc.

## cfar_sm --> Simulation using the CFAR detection algorithm
Note: the algorithm is still under test

The code outline follows:

1. Create radar object
2. Create target and environment objects
3. Simulation loop
    - Currently, the loop is run for a total of 1 second
    - the received echo is processed every t_step seconds
    - this means that in the intermediate intervals, the data is not observed, i.e. the target is made to hop
    from point to point, with a constant velocity
    - The simulation should be tested at the max update rate, which will generate a good amount of data
    - Decimation is used to simulate ADC sampling. The wave sample rate is related to the carrier as it needs
    to simulate this high freqeuncy.

4. Range and velocity estimates are plotted
5. Spectrums and signals plotted

## cfar_rd --> Real data processing using the CFAR detection algorithm
Similar to the above but for real data. Must use the data timestamps to get an average t_step time to use in simulation.
# Need to store data in an array before writing to file! and collect new data this way

## Rootmusic programs

These use the rootmusic algorithm instead of CFAR. Need to get it working on real data.