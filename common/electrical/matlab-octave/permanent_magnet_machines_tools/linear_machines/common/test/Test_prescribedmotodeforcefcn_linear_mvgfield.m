% Test_prescribedmotodeforcefcn_linear_mvgfield
%
% test with snapper stuff

clear; close all;

%% Set up the design

design.bpVTaup = 0.85; 
design.lmVbp = 0.2; 
design.dgVlm = 2.0; 
design.lsVTaup = 2;
design.dbiVlm = 0.5;
design.WcVTaup = 1/3;
design.hcVgap = 0.95;
design.Taup = 0.1;
design.Ntot = 1000;
design.CoilFillFactor = 0.55;
design.J = 0;
design.klineardrag = 0;
design.mu_fA = 0;
design.mu_fF = 0;
% design.massF = 100;
% design.weightF = 9.81 * design.massF;
design.mu_fT = 0;
design.massT = 0;
design.xSC = 0;
design.maxAllowedxA = inf;

design.Cd = 0;
design.DragArea = 0;


design = ratios2dimensions_ACPMSM(design);

design.AngleFromHorizontal = pi/2;
design.Phases = 3;
design.sides = 2; %hmmm
design.Poles = [12 1];
design.Ntot = 1000;
design.RlVRp = 10;
design.LgVLc = 0;
design.OuterWebs = 3;
design.GuideRailIMethod = '1.3';
design.GuideRailIVars = [0.1, 0.1, 0.095, 0.095];
% 
% % Get the dimensionless ratios from the parameters
% design = dimensions2ratios_ACPMSM(design);

% % set design mode
% design.mode = [1, 1, 0, 1];

design.OuterWebs = 3;
design.GuideRailIMethod = '1.3';
design.GuideRailIVars = [0.1, 0.1, 0.095, 0.095];
design.InnerStructureBeamVars = [];

% Calculate the extra length needed for the bearings
bearingWidth = 0.1; 
options.alphab = (design.ls + 2*bearingWidth) / design.ls;

% Common

design.ks = 1 * 60e3;
% design.FieldDirection = -1;

% design.HcMag = mgoe2hc(35);

design.MagCouple.hm = 0.025;

design.MagCouple.hms = 0.01;

design.MagCouple.g = 5/1000;

design.MagCouple.ht = 0.1;

design.MagCouple.htbi = design.MagCouple.ht/5;

design.MagCouple.Wt = 0.05;

design.MagCouple.Wr = 0.3;

design.MagCouple.Wms = 0.95*design.MagCouple.Wr;

design.MagCouple.Wm = 1.2 * design.MagCouple.Wt;

design.MagCouple.ls = 0.2;

design.MagCouple.FieldIronDensity = 7500;

design.MagCouple.FieldMagDensity = 7500;

design.MagCouple.N = 12;

%%

simoptions.ODESim.ResultsTSkip = 1;
simoptions.ODESim.TimeSpan = [0, 60];
simoptions.Lmode = 1;
simoptions.ODESim.InitialConditions = [0, 0, 0, 0, 0];

topspeed = 0.1;
simoptions.drivetimes = linspace(0, simoptions.ODESim.TimeSpan(2), 100);

% simoptions.vT = repmat(speed, size(simoptions.drivetimes));
simoptions.vT = (topspeed / simoptions.drivetimes(end)) * simoptions.drivetimes;

% simoptions.xT = simoptions.vT .* simoptions.drivetimes;
simoptions.xT = (topspeed / simoptions.drivetimes(end)) * (simoptions.drivetimes.^2 / 2);

simoptions.BuoySim.SeaParameters.rho = 0;

simoptions.NoOfMachines = 1;


simoptions.ODESim.PreProcFcn = 'simfun_MAGCOUPLE';
simoptions.ODESim.PostPreProcFcn = 'finfun_MAGCOUPLE';
% simoptions.ODESim.EvalFcn = @simplelinearmachineode_proscribedmotion;
simoptions.ODESim.EvalFcn = 'prescribedmotodeforcefcn_linear_mvgfield';
simoptions.ODESim.PostSimFcn = 'prescribedmotresfun_linear_mvgfield';
% simoptions.dpsidxfun = @polydpsidx_ACPMSM
simoptions.ODESim.ForceFcn = 'forcefcn_linear_mvgfield_pscbmot';
simoptions.ODESim.ForceFcnArgs = {};

simfunargs = {@simfun_ACPMSM};

finfunargs = {@finfun_ACPMSM_MC};

simoptions.rho = 0;

simoptions.backIronDensity = 7500;

simoptions.magnetDensity = 7800;


% design.FieldDirection = -1;

%%

[T, Y, results, design] = simulatemachine_linear(design, simoptions, ...
                                                 'simfunargs', simfunargs, ...
                                                 'finfunargs', finfunargs);
                                             
                                             
plotresultsproscribedmot_linear_mvgfield(T, Y, results, design, 1)

snapforce = design.MagCouple.N * max(slmeval(0:0.001:1, design.MagCouple.slm_FEAFy));

snapdist =  snapforce  / design.ks;

fprintf(1, '\nsnap force %f', snapforce)

fprintf(1, '\nsnap distance %f\n', snapdist)

design.GridMeanPower


%% no FEA

simoptions.ODESim.PreProcFcn = 'dummysimfun';
simfunargs = {@dummysimfun};

[T, Y, results, design] = simulatemachine_linear(design, simoptions, ...
                                                 'simfunargs', simfunargs, ...
                                                 'finfunargs', finfunargs);
                                             
                                             
plotresultsproscribedmot_linear_mvgfield(T, Y, results, design, 1)


snapforce = design.MagCouple.N * max(slmeval(0:0.001:1, design.MagCouple.slm_FEAFy));

snapdist =  snapforce  / design.ks;

fprintf(1, '\nsnap force %f', snapforce)

fprintf(1, '\nsnap distance %f\n', snapdist)

% 
% 
% %% Compare to no magcouple
% 
% 
% simoptions.ODESim.PreProcFcn = 'simfun_ACPMSM';
% simoptions.ODESim.PostPreProcFcn = 'systemfinfun_ACPMSM';
% simoptions.ODESim.EvalFcn = 'systemode_linear';
% simoptions.ODESim.PostSimFcn = 'systemresfun_linear';
% 
% simoptions.rho = 0;
% 
% [T, Y, results, design] = simulatemachine_linear(design, simoptions);
%                                              
%                                              
% plotresultsbuoysys_linear(T, Y, results, design, 1)
% 
% 
% design.GridMeanPower


