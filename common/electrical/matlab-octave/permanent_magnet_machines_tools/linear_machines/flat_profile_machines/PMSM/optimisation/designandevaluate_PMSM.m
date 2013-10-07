function [score, design, simoptions, T, Y, results] = designandevaluate_PMSM(design, simoptions)
% designandevaluate_PMSM: a function to evaluate a design of the linear
% permanent magnet machine as specified by it's dimensionless ratios and
% lengths, and magnet size
%
% Syntax:
%
%   CostPerW = designandevaluate_PMSM(design)
%   CostPerW = designandevaluate_PMSM(design, simoptions)
%   [CostPerW, design] = designandevaluate_PMSM(design)
%   [CostPerW, design] = designandevaluate_PMSM(design, simoptions)
%
% Input:
%
% design structure containingt the following members:
%
%   dgVlm - The air-gap + lm to lm ratio
%   
%   dtVdg - The tooth depth + dg to dg ratio
%   
%   bpVlm - The magnet height to width ratio
%   
%   taupVbp - The pole pitch to magnet height ratio
%   
%   lsVbp - The Tooth width in the z-direction to magnet height
%           (y-direction) ratio
%   
%   btVbc - The tooth height (y-direction) to total tooth and slot height
%           ratio (i.e. bc = Wp / 3 for 3-phase machine)
%   
%   dcVbs - The coil conductor diameter to slot height ratio
%
%   dtiVdt - The (air-gap + lm + hs) to (air-gap + lm + hs + half the
%            armature centre) ratio
%
%   dbiVlm - The Translator/Field back iron thickness to magnet thickness ratio 
%
%   RgVRc - The apparent grid resistance to coil resistance ratio
%
%   CoilFillFactor - the copper fill factor in the coil slots
%
%   lm - magnet depth
%
%   simoptions.evaloptions - optional structure containing various optional parameters for
%             the simultaion and evaluation. The following fields can be
%             specified:
%
%             E - (1 x 2) vector of youngs modulus values for the I-beams
%                 and the translator central section respectively (default:
%                 [200e9 151e9])
%
%             magCost - the cost per kg of magnet material (default: 30)
%
%             copperCost - the cost per kg of copper wire (default: 10)
%
%             backIronCost - the cost per kg of the back iron (default: 3)
%
%             armatureIronCost - the cost per kg of laminated iron core
%             material (default: 5)
%
%             structMaterialCost - the cost per kg of the structural
%             material, e.g. steel. (default: 3)
%
%             magnetDensity - density of magnet material (default: 7500
%             kg/m^3)
%
%             copperDensity - density of copper wire (default: 8960 kg/m^3)
%
%             backIronDensity - density of back iron (default: 7800 kg/m^3)
%
%             armatureIronDensity - density of laminated core material 
%             (default: 7800 kg/m^3)
%
%             structMaterialDensity - density of structuaral material 
%             (default: 7800 kg/m^3)
%
%             sections - the number of sections into which the beam is
%             split for analysis of the deflections due to maxwell stresses
%             (default: 10)
%
%             minRMSemf - the minimum operating RMS voltage
%
%             maxJrms - the minimum current density
%
%             alphab - the beam overlap factor for the bearings, i.e. if ls
%             is 1m and the stack length + bearings is 1.2 m long. Default
%             is 1.0, i.e. no extra length.
%
%             v - operating speed for linear power rating (default: 2.2
%             m/s)
%
%             pointsPerPole - number of points at which the voltage and
%             hence power will be evaluated for each pole (default: 40)
%
%             control - Determines if some kind of stator switching control
%             is used, if 0, none is used and the total phase resistance
%             will be higher due to inactive coils. If 1, only aoverlapping
%             coils are active and the resistance will be lower.
%
%             targetPower - If not zero, this is a target power rating for
%             the machine. The number of field Poles will be multiplied to
%             the required number to achieve this output power. If this is
%             present the system will look for the mlength field and act 
%             accordingly depending on what is found. (default: 500e3 W)
%
%             mlength - If targetPower is present and is zero, and mlength
%             is supplied, mlength should contain a vector of two lengths,
%             the field and armature respectively). If targetPower is zero
%             and mlength is not present it is set to one pole pitch for
%             each part. If targetPower is present and greater than zero,
%             mlength should be a scalar value of the overlap between field
%             and armature in metres. If not supplied, it is set to zero.
%             If there is no targetPower supplied, mlength should contain
%             the length of the field and armature. 
%
%             gfactor - A factor describing what fraction of the original
%             air gap size is allowed after deflection of the structure by
%             internal forces. Default is 0.9 meaning the airgap must be at
%             least 90 % of it's original value when the structure is
%             loaded.
% Output:
%
%

    
    simoptions = setfieldifabsent(simoptions, 'evaloptions', []);
    
    simoptions.evaloptions = designandevaloptions_PMSM(simoptions.evaloptions);

    simoptions.FieldIronDensity = simoptions.evaloptions.FieldIronDensity;
    simoptions.MagnetDensity = simoptions.evaloptions.MagnetDensity;
    simoptions.ShaftDensity = simoptions.evaloptions.StructMaterialDensity;
    simoptions.CopperDensity = simoptions.evaloptions.CopperDensity;
    simoptions.ArmatureIronDensity = simoptions.evaloptions.ArmatureIronDensity;
    
    [T, Y, results, design, simoptions] = evalsim_linear(design, simoptions);
    
    if isempty(simoptions.evaloptions.mlength)
        simoptions.evaloptions.mlength = [design.PoleWidth design.PoleWidth];
    end

    if isfield(design, 'minLongMemberPoles')
        if isfield(simoptions, 'StatorPoles')
            design.Poles(simoptions.StatorPoles) = design.minLongMemberPoles;
        else  
            % by default the armature is the stator which is stored in
            % design.Poles(1) for the PMSM
            design.Poles(1) = design.minLongMemberPoles;
        end
    end
    
    if design.Poles(1) == 1 && design.Poles(2) == 1
        
        if simoptions.evaloptions.targetPower == 0;
            
            design.Poles(1) = ceil(simoptions.evaloptions.mlength(2)/design.Wp);
            
            design.Poles(2) = ceil(simoptions.evaloptions.mlength(1)/design.Wp);
            
            design.PowerLoadMean = design.PowerLoadMean * design.Poles(2);
            
        else
            design.Poles(2) = ceil(simoptions.evaloptions.targetPower / design.PowerLoadMean);
            design.PowerLoadMean = design.PowerLoadMean * design.Poles(2);
            % if target power specified, simoptions.evaloptions.mlength is a scalar containing the
            % overlap required (in m) between the field and armature, i.e.
            % how much longer the armature is than the field
            design.Poles(1) = ceil(((design.Poles(2)*design.Wp)+simoptions.evaloptions.mlength)/design.Wp);
        end
        
    end
    
    design.PowerPoles = design.Poles(2);
    
    if ~isfield(design, 'BeamSpreadFactor')
        design.BeamSpreadFactor = 0;
    end
    
    airgapclosurefcn = @feairgapclosure_PMSM;
    structvolfcn = @structvol_PMSM;

    design = designstructure_FM_new(design, simoptions.evaloptions, structvolfcn, airgapclosurefcn);
    
    % Finally we determine the machine score and costs etc.
    [score, design] = machinescore_PMSM(design, simoptions);

    if isfield(design,'i')
        fprintf(1, 'Ind %d, Score:  %f\n', design.i, score);
    end
    
    % Do some final calculations
    design.fLength = design.Poles(2) * design.Wp;
    design.aLength = design.Poles(1) * design.Wp;

end