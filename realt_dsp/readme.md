## Call matlab engine

This can only run on a PC with MATLAB installed. The Python script reads in data from the uRAD/s and stores in a MATLAB workspace. A MATLAB processing script is called to process the data. Results are read from the workspace.

### 1. Configurable MATLAB workspace parameters
This option allows for changing the MATLAB parameters from within the Python script.

### 2. Preconfigured MATLAB workspace
A MATLAB script is used to generate all of the required variables beforehand, which are saved as a .mat file. The Python script loads this file instead of calling MATLAB functions to generate the base parameters.

### Note
The MATLAB engine takes a couple of seconds to boot


## Python plots

- These plot out the real time DSP and results thereof. 
- The plotting slows down processing
- VNC remote desktop runs very slowly
- SSH X forwarding runs slowly
- Storing as a JPEG is slow, though faster than the above methods

## Store results

- No plotting, though data is stored in arrays and finally written to a textfile. 
- Minimal effect on performance, though not as optimal as the full realtime system (no plot, no store)

## Pure system

- Only the final results are displayed.
- Results displayed in the CLI or using LEDs
- PWM to be implemented