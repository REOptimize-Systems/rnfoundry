%% ACTM

clear design simoptions

design.Phases = 3;         % Number of Phases in machine
design.Rm = 0.1;
design.g = 5/1000;
design.Ri = design.Rm + design.g;
design.WmVWp = 0.75;
design.WpVRm = 0.5;
design.RiVRm = design.Ri / design.Rm;
design.RoVRm = 1.2;
design.RaVRo = 1.025;
design.RsoVRm = 0.1;
design.RsiVRso = 0;
design.WcVWp = 1/3;
design.CoilFillFactor = 0.65;
%design.Dc = 1/1000;  % 1 mm diameter wire 
design.CoilTurns = 500;
design.mode = 2; 
design.LgVLc = 0;
design.Poles = [10 30];
% design.FieldDirection = 1;
% design.PowerPoles = Poles(1);

design = ratios2dimensions_ACTM(design);

%% Set up Common Parameters

design.RlVRp = 10;

simoptions.Lmode = 0;
simoptions.NoOfMachines = 1;
simoptions.maxAllowedxT = 0.5;

%% Test with linear motion

speed = 1;
simoptions.ODESim.InitialConditions = zeros(1, design.Phases);
simoptions.ODESim.ResultsTSkip = 1;
simoptions.ODESim.TimeSpan = [0, 5];
simoptions.drivetimes = 0:simoptions.ODESim.TimeSpan(2)/2:simoptions.ODESim.TimeSpan(2);
simoptions.vT = repmat(speed, size(simoptions.drivetimes));
simoptions.xT = simoptions.vT .* simoptions.drivetimes;
simoptions.BuoySim.tether_length = 0;
simoptions.NoOfMachines = 1;

simoptions.ODESim.EvalFcn = 'prescribedmotodeforcefcn_linear'; 
simoptions.ODESim.ForceFcn = 'forcefcn_linear_pscbmot'; 
simoptions.ODESim.PreProcFcn = 'simfun_ACTM';
simoptions.ODESim.PostSimFcn = 'prescribedmotresfun_linear'; 
simoptions.ODESim.PostPreProcFcn = 'prescribedmotfinfun_ACTM';

[T, Y, results, design] = simulatemachine_linear(design, simoptions); 

plotresultsproscribedmot_linear(T, Y, results, design, 1);     

