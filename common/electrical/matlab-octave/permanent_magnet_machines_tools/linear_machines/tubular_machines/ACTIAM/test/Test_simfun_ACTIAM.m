% Test_simfun_ACTIAM

clear design simoptions 

design.Phases = 3;         % Number of Phases in machine
design.Rm = 0.15;
design.g = 3/1000;
design.Ri = design.Rm + design.g;
design.WmVWp = 0.75;
design.WpVRm = 0.4;
design.RiVRm = design.Ri / design.Rm;
design.RoVRm = 1.2;
design.RaVRo = 1.03;
design.RsoVRm = 0.1;
design.RsiVRso = 0;
design.WcVWp = 1/3;
design.Rs2VHmag = 0.5;
design.Rs1VHmag = 0.5;
design.Ws2VhalfWs = 0.5;
design.Ws1VhalfWs = 0.5;

design.CoilFillFactor = 0.55;
design.Dc = 0.5/1000;        % 1 mm diameter wire 
design.mode = 2;
design.LgVLc = 0;
design.RlVRp = 10; % Ratio of machine resistance to grid resistance

design.Poles = [5 10];

design = ratios2dimensions_ACTIAM(design);

simoptions.GetVariableGapForce = true;
simoptions.NForcePoints = 12;

design.NStrands = 1;
design.NCoilsPerPhase = 1;

[design, simoptions] = simfun_ACTIAM(design, simoptions);

plotfemmproblem(design.FemmProblem);

hold on
contourf(design.X, design.Y .* design.Wp, design.A);
hold off

figure; scatter3(design.X(:), design.Y(:), design.Bx(:));

figure; scatter3(design.X(:), design.Y(:), design.By(:));

figure; scatter3(design.X(:), design.Y(:), design.A(:));

