function [u, d] = generate_sm_data()
    fc = 24.005e9;%77e9;
    c = physconst('LightSpeed');
    lambda = c/fc;
    tm = 1e-3;
    bw = 240e6;
    sweep_slope = bw/tm;
    range_max = 50;
    fr_max = range2beat(range_max,sweep_slope,c);
    v_max = 230*1000/3600;
    fd_max = speed2dop(2*v_max,lambda);
    fb_max = fr_max+fd_max;
    fs_wav = max(2*fb_max,bw);
    %fs_wav = 200e3; % kills range est
    rng(2012);
    waveform = phased.FMCWWaveform('SweepTime',tm,'SweepBandwidth',bw, ...
    'SampleRate',fs_wav, 'SweepDirection','Triangle');

    ant_aperture = 6.06e-4;                         % in square meter
    ant_gain = aperture2gain(ant_aperture,lambda);  % in dB
    
    tx_ppower = db2pow(5)*1e-3;                     % in watts
    tx_gain = 9+ant_gain;                           % in dB
    
    rx_gain = 15+ant_gain;                          % in dB
    rx_nf = 4.5;                                    % in dB
    
    transmitter = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
    receiver = phased.ReceiverPreamp('Gain',rx_gain,'NoiseFigure',rx_nf,...
    'SampleRate',fs_wav);

    car_dist = 50;
    car_speed = 80/3.6;
    car_rcs = db2pow(min(10*log10(car_dist)+5,20));
    
    cartarget = phased.RadarTarget('MeanRCS',car_rcs,'PropagationSpeed',c,...
    'OperatingFrequency',fc);
    
    carmotion = phased.Platform('InitialPosition',[car_dist;0;0.5],...
    'Velocity',[-car_speed;0;0]);
    
    channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs_wav,'TwoWayPropagation',true);
    
    radar_speed = 0;
    radarmotion = phased.Platform('InitialPosition',[0;0;0.5],...
    'Velocity',[radar_speed;0;0]);
    t_total = 1;
    t_step = 0.05;
    Nsweep = 2; % up and down
    n_steps = t_total/t_step;
    fs_adc = 200e3;% 2fbmax
    Dn = fix(fs_wav/fs_adc);
    n_samples = 200; % samples per sweep

    u = zeros(n_steps, n_samples);
    d = zeros(n_steps, n_samples);
    for t = 1:n_steps
        carmotion(t_step);
  
        xr = simulate_sweeps(Nsweep,waveform,radarmotion,carmotion,...
            transmitter,channel,cartarget,receiver);
        
        % Can change windowing
        u(t, :) = decimate(xr(:,1),Dn);
        d(t, :) = decimate(xr(:,2),Dn);
    end


