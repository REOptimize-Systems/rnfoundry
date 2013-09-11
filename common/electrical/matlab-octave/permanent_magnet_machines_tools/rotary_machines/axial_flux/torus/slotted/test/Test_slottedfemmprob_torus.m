% Test_slottedfemmprob_torus

% FemmProblem = newproblem_mfemm('planar');

% %   Materials
% Matlib = parsematlib_mfemm(fullfile(fileparts(which('mfemm_parsematlib.m')), 'matlib.dat'));
% 
% FemmProblem.Materials = Matlib([1, 47, 2]);


design.taupm = 1;
design.taumm = 0.8;

design.g = 0.1; 
design.tc = 0.15;
design.tsb = 0.025;
design.tsg = design.tsb;
design.ty = 0.15;

design.poles = 28;
design.phases = 3;
design.Qs = design.phases * 2 * 7;
design.yd = 1;
slotsperpole = design.slots / design.poles;
design.taucs = 0.8 * design.taupm / slotsperpole;
% design.taucs = 0.333 * design.taupm;

design.tm = 0.15;
design.tbi = [0.1, 0.2];

design.Rmo = 10;
design.Rmi = 9;

design.Hc = design.tc;
design.Wc = design.taucs;
design.tausgm = design.Wc * 0.3;

design.Dc = design.taumm / 100;
design.fillfactor = 0.7;

design.CoilTurns = 250;

design.MagnetMaterial = 'NdFeB 32 MGOe';
design.BackIronMaterial = '1117 Steel';
design.YokeMaterial = design.BackIronMaterial;
design.CoilMaterial = '36 AWG';

[FemmProblem, outermagsep] = slottedfemmprob_torus(design, 'NStages', 1, 'NWindingLayers', 2);


filename = 'test.fem';

writefemmfile(filename, FemmProblem)

openfemm;

opendocument(fullfile(pwd, filename))

