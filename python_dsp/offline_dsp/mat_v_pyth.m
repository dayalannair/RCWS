addpath('../../matlab_dsp/triangle_fmcw/real_data/');

py_rg_tbl = readtable("range_results.txt", 'Delimiter',' ');
py_sp_tbl = readtable("speed_results.txt", 'Delimiter',' ');
py_sf_tbl = readtable("safety_results.txt", 'Delimiter',' ');

mt_rg_tbl = readtable("mt_range_results.txt", 'Delimiter',' ');
mt_sp_tbl = readtable("mt_speed_results.txt", 'Delimiter',' ');
mt_sf_tbl = readtable("mt_safety_results.txt", 'Delimiter',' ');

py_rg_array = table2array(py_rg_tbl);
py_sp_array = table2array(py_sp_tbl);
py_sf_array = table2array(py_sf_tbl);

mt_rg_array = table2array(mt_rg_tbl);
mt_sp_array = table2array(mt_sp_tbl);
mt_sf_array = table2array(mt_sf_tbl);

%%
axes = [0 length(py_rg_array) 0 60];
close all
figure
tiledlayout(3,2)
nexttile
plot(py_rg_array)
title("Python DSP Range vs. Time")
ylabel("Range (m)")
xlabel("Sweep number")
axis(axes)
nexttile
plot(mt_rg_array)
title("MATLAB DSP Range vs. Time")
ylabel("Range (m)")
xlabel("Sweep number")
axis(axes)
nexttile
plot(py_sp_array*3.6)
title("Python DSP Speed vs. Time")
ylabel("Speed (km/h)")
xlabel("Sweep number")
axis(axes)
nexttile
plot(mt_sp_array*3.6)
title("MATLAB DSP Speed vs. Time")
ylabel("Speed (km/h)")
xlabel("Sweep number")
axis(axes)
nexttile
% imagesc(3-py_sf_array(sf_subset))
plot(py_sf_array)
title("Python Time of arrival vs Time")
ylabel("Time of arrival (s)")
xlabel("Sweep number")
nexttile
plot(mt_sf_array)
title("MATLAB Time of arrival vs Time")
ylabel("Time of arrival (s)")
xlabel("Sweep number")
return
%%
sf_subset = 400:600;
close all
figure
tiledlayout(3,2)
nexttile
imagesc(py_rg_array)
title("Python DSP Time vs. Range bin vs. Range")

nexttile
imagesc(mt_rg_array)
title("MATLAB DSP Time vs. Range bin vs Range")
ylabel("Range (m)")
xlabel("Sweep number")
nexttile
imagesc(py_sp_array)
title("Python DSP Time vs. Range bin vs Speed")

nexttile
imagesc(mt_sp_array)
title("MATLAB DSP Time vs. Range bin vs Speed")
ylabel("Speed (km/h)")
xlabel("Sweep number")
nexttile
% imagesc(3-py_sf_array(sf_subset))
plot(py_sf_array)
title("Python Time of arrival vs Time")
ylabel("Time (s)")
xlabel("Sweep number")
nexttile
plot(mt_sf_array)
title("MATLAB Time of arrival vs Time")
ylabel("Time (s)")
% imagesc(3-mt_sf_array(sf_subset))
% imagesc(py_rg_array)
% imagesc(py_sf_array)