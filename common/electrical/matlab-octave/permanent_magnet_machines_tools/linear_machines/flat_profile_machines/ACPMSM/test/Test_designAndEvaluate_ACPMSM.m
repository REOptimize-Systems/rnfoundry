% Test_designAndEvaluate_ACPMSM

clear 

% bpVTaup, lmVbp, dgVlm, lsVTaup, dbiVlm, Taup, WcVTaup, hcV2dg

design.bpVTaup = 0.85; 
design.lmVbp = 0.2; 
design.dgVlm = 2.0; 
design.lsVTaup = 3;
design.dbiVlm = 1;
design.WcVTaup = 1/3;
design.HcVgap = 0.95;
design.Taup = 0.2;
design.CoilTurns = 1000;
design.CoilFillFactor = 0.55;
design.J = 0;

design = ratios2dimensions_ACPMSM(design);

design.AngleFromHorizontal = pi/2;
design.Phases = 3;
design.Poles = 5;
design.CoilTurns = 1000;
design.RgVRc = 10;
design.LgVLc = 0;
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

%%

% speed = 1;
% simoptions.IC = 0;
% simoptions.skip = 1;
% simoptions.tspan = [0, 10];
% simoptions.drivetimes = 0:simoptions.tspan(2);
% simoptions.vT = repmat(speed, size(simoptions.drivetimes));
% simoptions.xT = simoptions.vT .* simoptions.drivetimes;
% simoptions.Lmode = 1;

% use buoy number 37, 4m diameter, 2m draft
simoptions.buoy = 'cyl_4dia_2dr';

% NSsimoptions.SeaParameters = seasetup('sigma', 2 * pi * 0.35, ...
%                                     'phase', pi / 2);

simoptions.SeaParameters = seasetup('PMPeakFreq', 1/9);

simoptions.tether_length = 5;
simoptions.water_depth = 40;

simoptions.tspan = [0, 60];
simoptions.Lmode = 1;
simoptions.IC = [0, 0, 0];

simoptions.simfun = 'simfun_ACPMSM';
simoptions.finfun = 'systemfinfun_ACPMSM';
% simoptions.odeevfun = @simplelinearmachineode_proscribedmotion;
simoptions.odeevfun = 'systemode_linear';
simoptions.resfun = 'systemresfun_linear';
% simoptions.dpsidxfun = @polydpsidx_ACPMSM;


%%

[score, design, simoptions, T, Y, results] = designandevaluate_ACPMSM(design, simoptions);

%%

plotresultsbuoysys_linear(T, Y, results, design, 1)
