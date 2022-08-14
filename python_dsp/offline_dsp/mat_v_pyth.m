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
close all
figure
tiledlayout(3,2)
nexttile
imagesc(py_rg_array)
nexttile
imagesc(mt_rg_array)
nexttile
imagesc(py_sp_array)
nexttile
imagesc(mt_sp_array)
nexttile
imagesc(py_sf_array)
nexttile
imagesc(mt_sf_array)
% imagesc(py_rg_array)
% imagesc(py_sf_array)