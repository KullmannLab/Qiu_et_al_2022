%%For .txt files exported from WinWCP. e.g. File,export, ASCII Txt, select
%'save records as columns'. Outputs as
%Time,voltage(sweep1),current(sweep1),voltage(sweep2),current(sweep2), voltage(sweepn),current(sweepn).

clear
Path = "C:\Users\natha\Documents\ADPD files\c-Fos\c-FosKCNJ2\NN210227_011[1-21][Vm1,Im1].txt" %path to file
File = importdata (Path); %imports data
RawFileTable = File(:,[1 2:2:end]); %extracts first column (Time), second column (voltage(sweep1)), and every other column (skips current)

Vthresh = 0
SampInterval = (RawFileTable(2)) - (RawFileTable(1));
SampRate = 1/SampInterval;
RawVoltage =(RawFileTable(:,2:22));
RawVoltageLinear = RawVoltage(:);

Threshcrossings = RawVoltageLinear >=Vthresh; %finds when voltage crosses zero (e.g. APs).
FirstThreshcrossingSample = (find(Threshcrossings, 1, 'first')) %finds first instance of this (e.g. first AP)
FirstThreshcrossingSweep = FirstThreshcrossingSample/93696 %finds what sweep it occured on (93696 = samples per sweep)
[Extraction] = [FirstThreshcrossingSample - (0.002*SampRate), FirstThreshcrossingSample + (0.01*SampRate)]; %extracts window around first AP
APVoltages = (RawVoltageLinear(Extraction(1,1): Extraction(1,2)));
APtimes = (SampInterval*(0:((Extraction(1,2)-Extraction(1,1)))));
APTimes = APtimes(:);
APTimesms = APTimes*1000;
AP = [APTimes,(APVoltages)];
APfig = plot(AP(:,1),AP(:,2));
dy=gradient(APVoltages)./gradient(APTimesms); %first derivative of action potential (dmV/dms)
dythresh = 20; %dy/dx treshold (20 mV/ms)
dythreshold = dy >=dythresh; %0 or 1 based on if differential is above the threshold or not
FirstdyThreshcrossingSample = (find(dythreshold, 1, 'first')); %finds first instance of this e.g. threshold sample position
ThresholdmV = APVoltages(FirstdyThreshcrossingSample); %finds corresponding threshold voltage
Thresholdpositionms = (FirstdyThreshcrossingSample * SampInterval)*1000; %And Time
PeakmV = max(APVoltages); %max value of AP
Peakposition = find(APVoltages == PeakmV,1,'first'); %finds the position of this peak (first because may be two sampling points with this value
Peakpositionms = (Peakposition * SampInterval)*1000; %position of the peak of AP
APheightmV = PeakmV - ThresholdmV; %AP height
AHPmV = min(APVoltages(FirstdyThreshcrossingSample:(Peakposition +(0.005*SampRate)))) - ThresholdmV; %Finds the minimum value from threshold to 5 ms after AP peak to get the AHP.
AHPsampleposition = find((APVoltages)==(min(APVoltages(FirstdyThreshcrossingSample:(Peakposition +(0.005*SampRate)))))); 
AHPpositionms = (AHPsampleposition * SampInterval)*1000;
AHPtracemV = (ThresholdmV + AHPmV);
MaxRise = max(dy);
MaxDecay = min(dy);
halfamp = ThresholdmV + (0.5 * APheightmV);
step1halfw = APVoltages - halfamp; % taking away half the amplitude from AP voltages. E.G at zero then the amplidue of the AP and the half amp are the same
step2halfw = find(step1halfw>=0,1,'first'); %Find the first position of these deducted values where the value>0 e.g. 2 mV may be the half the peak. at threshold e.g -40 = -40 -2 = -42; at zero mV = 0-2 mV = -2 mV at 2 mV = 2 - 2 mV = 0mV = half way up the AP
step3halfw = step1halfw (Peakposition:end); %makes a vector from the peak to the rest of the trace (for findng the half value on the falling phase)
step4halfw = find(step3halfw<=0,1,'first'); %Finds the value for when the falling phasse is equal or below to half width
step5halfw = (Peakposition - 1) + step4halfw; %adds position on the falling phase to the prepeak (-1 to avoid duplication of numbers)
Halfwidthsamples = step5halfw - step2halfw;
Halfwidthms = ((Halfwidthsamples) * (SampInterval))*1000;
Halfwidthrisems = ((step2halfw) * (SampInterval))*1000; 
Halfwidthfallms = ((step5halfw) * (SampInterval))*1000;
halfwidthx = [Halfwidthrisems,Halfwidthfallms];
Halfwidthx = halfwidthx(:);
plot(APTimesms,APVoltages,Thresholdpositionms,ThresholdmV,'o',Peakpositionms,PeakmV,'o',AHPpositionms,AHPtracemV,'o',Halfwidthx,halfamp,'o')
aAPSummary = table (ThresholdmV,PeakmV,APheightmV,AHPmV,Halfwidthms,MaxRise,MaxDecay,FirstThreshcrossingSweep)

