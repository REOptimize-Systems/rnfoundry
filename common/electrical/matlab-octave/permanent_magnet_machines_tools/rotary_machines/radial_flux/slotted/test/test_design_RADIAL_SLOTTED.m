function design = test_design_RADIAL_SLOTTED (armtype)
% produces a slotted radial flux design structure for testing purposes

    if nargin < 1
        armtype = 'external';
    end
    
    design.ArmatureType = armtype;
    design.Poles = 12;
    design.Phases = 3;
    design.CoilLayers = 2;
    design.Qc = design.Phases * design.Poles;
    if design.CoilLayers == 1
        design.Qs = 2 * design.Qc;
    elseif design.CoilLayers == 2
        design.Qs = 1 * design.Qc;
    end
    design.qc = fr (design.Qc, design.Poles * design.Phases);
    design.yd = 4;
    design.thetap = 2*pi/design.Poles;
    design.thetam = design.thetap * 0.8;
    design.thetacg = (2*pi / design.Qs) * 0.7;
    design.thetacy = (2*pi / design.Qs) * 0.9;
    design.thetac = [design.thetacg, design.thetacy];
    design.thetasg = design.thetacg * 0.6;
    design.tm = 0.0010;
    design.tbi = 0.001;
    design.ty = 0.001;
    design.tc = 0.003;
    design.tsb = 0.001;
    design.tsg = design.tsb * 0.3; %0; %0.01;
    design.g = 3/1000;
    design.Rmo = 0.05;
    design.Rmi = 0.05;
    design.ls = 0.03;

    if strcmp(design.ArmatureType, 'external')
        design.Rmo = 0.05;
        design.Rmi = design.Rmi - design.tm;
        design.Rmm = mean([design.Rmi, design.Rmo]);
        design.Rci = design.Rmo + design.g + design.tsb;
        design.Rco = design.Rci + design.tc;
        design.Rcm = mean([design.Rci, design.Rco]);
        design.Rbo = design.Rmi;
        design.Rbi = design.Rbo - design.tbi;
        design.Rbm = mean([design.Rbo, design.Rbi]);
        design.Ryi = design.Rco;
        design.Ryo = design.Rco + design.ty;
        design.Rym = mean([design.Ryi, design.Ryo]);
    elseif strcmp(design.ArmatureType, 'internal')
        design.Rmi = 0.05;
        design.Rmo = design.Rmi + design.tm;
        design.Rmm = mean([design.Rmi, design.Rmo]);
        design.Rco = design.Rmi - design.g - design.tsb;
        design.Rao = design.Rco + design.tsb;
        design.Rci = design.Rco - design.tc;
        design.Rcm = mean([design.Rci, design.Rco]);
        design.Rbi = design.Rmo;
        design.Rbo = design.Rbi + design.tbi;
        design.Rbm = mean([design.Rbo, design.Rbi]);
        design.Ryo = design.Rci;
        design.Ryi = design.Ryo - design.ty;
        design.Rym = mean([design.Ryi, design.Ryo]);
    end

    design.Dc = design.Rcm * mean (design.thetac) / 100;
    design.CoilFillFactor = 0.7;

    design.Hc = design.tc / design.CoilLayers;
    design.CoilTurns = 25;

    design.NCoilsPerPhase = design.Qc / design.Phases;

    design.MagFEASimMaterials.Magnet = 'NdFeB 40 MGOe';
    design.MagFEASimMaterials.FieldBackIron = '1117 Steel';
    design.MagFEASimMaterials.ArmatureYoke = design.MagFEASimMaterials.FieldBackIron;
    design.MagFEASimMaterials.ArmatureCoil = '36 AWG';
    design.MagFEASimMaterials.AirGap = 'Air';
    design.MagFEASimMaterials.CoilInsulation = 'Air';
    
    design.HeatFEASimMaterials.Magnet = 'Iron, Pure';
    design.HeatFEASimMaterials.FieldBackIron = 'Iron, Pure';
    design.HeatFEASimMaterials.ArmatureYoke = design.MagFEASimMaterials.FieldBackIron;
    design.HeatFEASimMaterials.ArmatureCoil = 'Copper, Pure';
    design.HeatFEASimMaterials.AirGap = 'Water';
    design.HeatFEASimMaterials.CoilInsulation = 'Water';

end
