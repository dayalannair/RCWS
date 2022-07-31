# Radar Intersection Collision Prediction System (R-ICPS)

## Task list

- [ ] Add all work to report - remember to use issues and discussions from old repo
- [ ] Improve bin method by restricting 'search' area for triangle modulation/ I.e. based on fbd, where can we expect fbu?
- [ ] Improve Python OS CFAR
- [ ] Test full Python realtime version on PC and RPI
- [ ] Integrate Pi camera and show real time plots of spectra, results, and video (similar to MATLAB offline processing)
- [ ] Modify real time Python program to work with two uRADs
- [ ] Modify dual radar Python program to incorporate two cameras. Pi can support one Pi cam and one USB camera
- [ ] Consider a Pi network - control and sensor nodes
- [ ] Create condensed Python program (no GUI) as required by the prototype
- [ ] Test system - both GUI and no GUI - on road side
- [ ] Install system on car and test in controlled and (or) road environments
- [ ] Neaten simulations and present in report
- [ ] clean up/neaten repository

### Link to data storage:
https://uctcloud-my.sharepoint.com/:f:/g/personal/nrxday001_myuct_ac_za/EjFL7omlg09PrdxWb3c22k4BgLi7pwkYM-8y16FP6_n1MA?e=45jsQ6

### Notes: 
- add data and library folders to MATLAB path after clone not needed if addpath() is called in each script
- Data collection/radar programs are in data/urad_usb
- make sure textfiles/data is never committed - deletion will not remove data from version history and so increase repo size
- in the event a repo gets too large, use filter-repo (3rd party program) to filter *.txt etc and push to a new repo
- USB for linux found using lsusb. Currently using ACM0. Device is infineon technologies

