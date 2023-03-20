phased_scenario1;
%%
% close all
% get number of elements
samples = numel(rxsig);
% concatenate each sweep/target position result 
% into a single vector
data = reshape(rxsig, 1, samples);

% define time and distance axes. Note the variables are declared in
% previous scripts
t = 1:tau:Nsweep*tau;
d = t.*(c/2);

% convert to frequency domain
%DATA = fftshift(fft(data,[],1),1);
DATA = fftshift(fft(data));

figure
tiledlayout(3,1);

nexttile
% spectrograph i.e. colour map with yellow being highest value
imagesc(20*log10(abs(DATA)))

nexttile
% plot real received signal in frequency domain
plot(abs(DATA))

nexttile
plot(real(data))


% nexttile
% rxsig = pulsint(rxsig,'noncoherent');
% t = unigrid(0,1/receiver.SampleRate,T,'[)');
% rangegates = (physconst('LightSpeed')*t)/2;
% plot(rangegates/1e3,rxsig)
% hold on
% xlabel('range (km)')
% ylabel('Power')
% xline([tgtrng/1e3,tgtrng/1e3],'r')
% hold off
step_names = strings(400);
for w = 1:400
    step_names(w) = "Step " + w;
end
figure
tiledlayout(2,1)
RXSIG = fft(rxsig);
nexttile
plot(real(rxsig))
nexttile
plot(abs(RXSIG))
legend(step_names);
% for e = 1:400
% 
%     hold on
%     plot(rearxsig(:,e))
% 
% end







