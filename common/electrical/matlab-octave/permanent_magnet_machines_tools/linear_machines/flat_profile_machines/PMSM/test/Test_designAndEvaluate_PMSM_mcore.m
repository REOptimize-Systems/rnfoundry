%% Test_designandevaluate_PMSM

% First we need some plausible machine variables for testing, we will use
% the AWS variables for this
clear

design.Phases = 3;
design.Wp = 0.12;
design.Wm = 0.8*design.Wp;
design.hm = 0.015;
design.kw = 0.84;
%Ns = 470;
%Ns = 6; % ???
design.Hc = 979000;
%ht = 0.1;
design.CoilFillFactor = 0.585;
design.g = 0.003; 
design.ls = 0.5; 
design.Dc = 0.005; 
design.E = [200e9 151e9];
design.Wc=design.Wp/design.Phases;
design.Ws=design.Wc/2; 
design.Wt=design.Wc/2;
design.ht=5*design.Wt;
design.hbf = design.hm;
design.hba = design.hbf;

% Number of turns
%design.Poles = [1 1];
% design.Ntot = 400;
design.RlVRp = 10;
design.LgVLc = 0;
design.BeamSpreadFactor = 0.8;

% Get the dimensionless ratios from the parameters
design = dimensions2ratios_PMSM(design);

% set design mode
design.mode = [1, 1, 0, 1];

design.OuterWebs = 3;
design.GuideRailIMethod = '1.3';
design.GuideRailIVars = [0.1, 0.1, 0.095, 0.095];
design.InnerStructureBeamVars = [];

% Calculate the extra length needed for the bearings
bearingWidth = 0.1; 
options.alphab = (design.ls + 2*bearingWidth) / design.ls;
options.InitDef = [0.2/1000;0.2/1000;0.2/1000];

design.tols = options.InitDef;

%% Test with linear motion

speed = 1;
simoptions.ODESim.TimeSpan = [0, 10];
simoptions.drivetimes = 0:simoptions.ODESim.TimeSpan(2);
simoptions.vT = repmat(speed, size(simoptions.drivetimes));
simoptions.xT = simoptions.vT .* simoptions.drivetimes;

simoptions.ODESim.PreProcFcn = @simfunnocurrent_PMSM;
simoptions.ODESim.PostPreProcFcn = @finfun_PMSM;
simoptions.ODESim.EvalFcn = @simplelinearmachineode_proscribedmotion;
simoptions.ODESim.PostSimFcn = @resfun_linear;

design.Poles = [1, 1];
options.targetPower = 10e3; % 10kW machine

%% Test with buoy

simoptions = buoysimoptions;

% Set up the buoy and sea data files, these are for the 2m buoy
% snappertrunkdir = fileparts(which('wholesystemsim_Snapper'));
% simoptions.HeaveFile = fullfile(getbuoylibdir, 'Cylinder_2m_dia_d010410', 'heave_coefficients_cyl_2di_1dr_d020610.mat');
% simoptions.SurgeFile = fullfile(getbuoylibdir, 'Cylinder_2m_dia_d010410', 'surge_coefficients_cyl_2di_1dr.mat');
% simoptions.HydroCoeffsFile = fullfile(getbuoylibdir, 'Cylinder_2m_dia_d010410','cyl_d3103v4.1');
% simoptions.ExcitationFile = fullfile(getbuoylibdir, 'Cylinder_2m_dia_d010410','cyl_d3103v4.2');
% simoptions.BuoySim.BuoyParameters = load(fullfile(getbuoylibdir, 'Cylinder_2m_dia_d010410', 'buoyparams_d3103v4.mat'));
% simoptions.buoy = [];
simoptions.buoy = 'cyl_4dia_2dr';

buoy = buoysetup('cyl_4dia_2dr');

simoptions.ODESim.TimeSpan = [0, 60];
% params.amp = 1;
params.peak_freq = 0.35; % centred at resonant frequency
% params.phase = pi/2;
params.water_depth = 50;

% simoptions.BuoySim.SeaParameters = defaultseaparamaters(params);
simoptions.BuoySim.SeaParameters = seasetup('PMPeak', 1/9, ...
                                    'nooff', 50, ...
                                    'WaterDepth', 50, ...
                                    'minfreq', buoy.BuoyParameters.minfreq, ...
                                    'maxfreq', buoy.BuoyParameters.maxfreq);

simoptions.BuoySim.tether_length = 4;


simoptions.ODESim.PreProcFcn = 'simfunnocurrent_PMSM';
simoptions.ODESim.EvalFcn = 'systemode_linear'; 
simoptions.ODESim.PostPreProcFcn = 'systemfinfun_PMSM';
simoptions.ODESim.PostSimFcn = 'systemresfun_linear'; 

design.Poles = [18, 6];

%% Run locally

simoptions.Lmode = 1;
simoptions.ODESim.InitialConditions = zeros(1,design.Phases);
simoptions.ODESim.ResultsTSkip = 1;
simoptions.Translator = 2;

% Overlap between stator and translator, i.e. stator is mleng metres longer
% than the translator
% options.alphab = 1.05;
% Young's modulus of elasticity for Structural steel and laminated steel respectively
simoptions.Evaluation.E = [200e9 151e9];  
% options.mlength = 6; 

[score, design, simoptions, T, Y, results] = designandevaluate_PMSM(design, simoptions);

% plotresultsbuoysys_linear(T, Y, results, design, 1)

%% Run on multicore

