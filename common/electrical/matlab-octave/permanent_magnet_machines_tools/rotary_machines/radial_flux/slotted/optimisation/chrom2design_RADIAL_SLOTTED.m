function [design, simoptions] = chrom2design_RADIAL_SLOTTED(simoptions, Chrom, varargin)
% converts a chromosomal representation of a slotted radial flux machine to
% a full machine design in preparation for simulation
%
% Syntax
%
% [design, simoptions] = chrom2design_RADIAL_SLOTTED(simoptions, Chrom, 'Parameter', Value)
%
%

% Copyright 2012-2013 Richard Crozier

    % number of Phases
    options.Phases = 3;
    % number of coils per pole and phase
    options.qc = fr(3,3);
    % grid resistance to phase resistance ratio
    options.RlVRp = 10;
    % coil fill factor
    options.CoilFillFactor = 0.65;
    % branch factor, determines number of parallel and series coils
    options.BranchFac = 0;
%     options.ModuleFac = 0;
    % stator type, determines if we have an outer facing or inner facing
    % stator
    options.ArmatureType = 'internal';
    % number of coil layers
    options.CoilLayers = 2;
    % maximum permitted radial coil height
    options.Max_tc = 0.2;
    % maximum permitted radial magnet height
    options.Max_tm = 0.05;
    % maximum stack length
    options.Max_ls = 4;
    % maximum ratio of ty to tm
    options.Max_tyVtm = 3;
    % minimum permitted air gap
    options.Min_g = 0.5/1000;
    options.Max_tsbVtc = 0.1;
    
    % parse the input options, replacing defaults
    options = parseoptions(options, varargin);
    
    % copy the resulting options into the appropriate places
    design.ArmatureType = options.ArmatureType;
    design.CoilFillFactor = options.CoilFillFactor;
    design.Phases = max(1, round(options.Phases));
    design.qc = options.qc;
    design.RlVRp = options.RlVRp;
    design.CoilLayers = options.CoilLayers;
%     design.ModuleFac = options.ModuleFac;
    
    if strcmp(design.ArmatureType, 'external')

        error('Stator Type ''external'' not yet supported.')

    elseif strcmp(design.ArmatureType, 'internal')

        design = chrom2design_internal_arm (design, simoptions);
        
    end
    
    % prevent overly deep stack lengths
    if design.ls > options.Max_ls
       design.ls = options.Max_ls;
       design.lsVtm = design.ls / design.tm;
    end
    
    design.Hc = design.tc;
    design.Wc = design.thetac * design.Rcm;
    
    design = preprocsystemdesign_RADIAL(design, simoptions);

    % recall completedesign_RADIAL_SLOTTED  to recalculate the design dims
    % and ratios in case they have been modified
    
    % remove some fields first to ensure the ratios are recalculated from
    % the correct dimensions
    % 'RmiVRmo' and 'g' are used in both internal and external armature
    % configurations, remove them to force recalcualtion based on radial
    % dimensions
    design = rmfield (design, 'RmiVRmo');
    design = rmfield (design, 'g');
    design = completedesign_RADIAL_SLOTTED (design, simoptions);
    
end

function design = chrom2design_external_arm (design, simoptions)

       
    % convert machine ratios to actual dimensions
    design.Ryo = Chrom(1);
    design.RyiVRyo = Chrom(2);
    design.RtsbVRyi = Chrom(3);
    design.RaiVRtsb = Chrom(4);
    design.tsgVtsb = Chrom(5);
    design.RmoVRai = Chrom(6);
    design.RmiVRmo = Chrom(7);
    design.RbiVRmi = Chrom(8);
    design.thetamVthetap = Chrom(9);
    design.thetacVthetas = Chrom(10);
    design.thetasgVthetac = Chrom(11);
    design.lsVtm = Chrom(12);
    design.NBasicWindings = round(Chrom(13));
    design.DcAreaFac = Chrom(14);
    design.BranchFac = Chrom(15);
    
    if numel(Chrom) > 15
        design.MagnetSkew = Chrom(16);
    end

%         factors = factor2(design.NBasicWindings)';
% 
%         % now determine the number of modules to use
%         modulecomp = design.ModuleFac * design.NBasicWindings;
% 
%         NearestFacStruct = ipdm(modulecomp, factors, ...
%                                 'Subset', 'NearestNeighbor', ...
%                                 'Result', 'Structure');
% 
%         design.NModules = factors(NearestFacStruct.columnindex, NearestFacStruct.rowindex);

    design = completedesign_RADIAL_SLOTTED(design, simoptions);

    if (design.tsb > 0) && (design.tsb / design.tc) > options.Max_tsbVtc
        % shift the shoe base inward
        rshift = (design.tsb - (design.tc*options.Max_tsbVtc));
        design.Rtsb = design.Rtsb - rshift;
        design.tsb = design.tc*options.Max_tsbVtc;
        % recalculate the shoe gap size
        design.tsg = design.tsb * design.tsgVtsb;
        design.Rtsg = design.Rai + design.tsg;
        design = updatedims_exteral_arm(design);
    end

    if design.tc > options.Max_tc
        % move the stator yoke inwards to reduce the size of the slot
        rshift = (design.tc - options.Max_tc);
        design.Ryi = design.Ryi - rshift;
        design.Ryo = design.Ryo - rshift;
        design = updatedims_exteral_arm(design);
    end

    if (design.ty / design.tm) > options.Max_tyVtm
        % move the stator yoke internal radius inwards to reduce the
        % thickness of the yoke
        rshift = design.ty - (design.tm * options.Max_tyVtm);
        design.Ryo = design.Ryo - rshift;
        design = updatedims_exteral_arm(design);
    end

    if design.tm > options.Max_tm
        rshift = design.tm - options.Max_tm;
        design.tm = options.Max_tm;
        design.Rmi = design.Rmi + rshift;
        design.Rbi = design.Rbi + rshift;
        design = updatedims_exteral_arm(design);
    end

    % here we handle the 
    if design.tsb > 0 && (design.tsg < design.tsb)

        x = ((design.thetac - design.thetasg)/2) * (design.Rao - design.tsb);
        y = design.tsb - design.tsg;

        tsbangle = rad2deg(atan( y / x ));

        if design.tsg < 1e-5
            x = ((design.thetac - design.thetasg)/2) * (design.Rao - design.tsb);
            y = design.tsb;
            tsgangle = rad2deg(atan( y / x ));
        else
            tsgangle = inf;
        end

        if tsbangle < 15 || tsgangle < 15

            rshift = design.tsb;
            design.tsb = 0;
            design.tsg = 0;
            design.Ryi = design.Ryi + rshift;
            design.Ryo = design.Ryo + rshift;
            design.Rci = design.Ryo;
            design.Rco = design.Rco + rshift;
            design.Rao = design.Rco;
            design.Rtsb = design.Rco;
            design.Rtsg = design.Rco;

            design = updatedims_exteral_arm(design);
        end

    end

    if design.g < options.Min_g
        % increase the outer diameter
        rshift = (options.Min_g - design.g);
        design.Rai = design.Rai + rshift;
        design.Rtsb = design.Rtsb + rshift;
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        
        design = updatedims_exteral_arm(design);
    end
        
end

function design = updatedims_exteral_arm(design)

    % some additional radial variables
    design.Rco = design.Rtsb;
    design.Rci = design.Ryi;
    design.Rbo = design.Rmi;

    % lengths in radial direction
    design.ty = design.Ryo - design.Ryi;
    design.tc = design.Rco - design.Rci;
    design.tsb = design.Rtsb - design.Rai;
    design.g = design.Rai - design.Rmi;
    design.tm = design.Rmo - design.Rmi;
    design.tbi = design.Rbo - design.Rbi;

    % the shoe tip length
    design.Rtsg = design.Rai + design.tsg;

    % mean radial position of magnets
    design.Rmm = mean([design.Rmo, design.Rmi]);
    design.Rcm = mean([design.Rci, design.Rco]);
    design.Rbm = mean([design.Rbo, design.Rbi]);
    design.Rym = mean([design.Ryi, design.Ryo]);

end


function design = chrom2design_internal_arm (design, simoptions)

    % convert machine ratios to actual dimensions
    design.Rbo = Chrom(1);
    design.RmoVRbo = Chrom(2);
    design.RmiVRmo = Chrom(3);
    design.RaoVRmi = Chrom(4);
    design.RtsbVRao = Chrom(5);
    design.tsgVtsb = Chrom(6);
    design.RyoVRtsb = Chrom(7);
    design.RyiVRyo = Chrom(8);
    design.thetamVthetap = Chrom(9);
    design.thetacVthetas = Chrom(10);
    design.thetasgVthetac = Chrom(11);
    design.lsVtm = Chrom(12);
    design.NBasicWindings = round(Chrom(13));
    design.DcAreaFac = Chrom(14);
    design.BranchFac = Chrom(15);
    
    if numel(Chrom) > 15
        design.MagnetSkew = Chrom(16);
    end

%         factors = factor2(design.NBasicWindings)';
% 
%         % now determine the number of modules to use
%         modulecomp = design.ModuleFac * design.NBasicWindings;
% 
%         NearestFacStruct = ipdm(modulecomp, factors, ...
%                                 'Subset', 'NearestNeighbor', ...
%                                 'Result', 'Structure');
% 
%         design.NModules = factors(NearestFacStruct.columnindex, NearestFacStruct.rowindex);

    design = completedesign_RADIAL_SLOTTED(design, simoptions);

    if (design.tsb > 0) && (design.tsb / design.tc) > options.Max_tsbVtc
        % shift the shoe base outward
        rshift = (design.tsb - (design.tc*options.Max_tsbVtc));
        design.Rtsb = design.Rtsb + rshift;
        design.tsb = design.tc*options.Max_tsbVtc;
        % recalculate the shoe gap size
        design.tsg = design.tsb * design.tsgVtsb;
        design.Rtsg = design.Rao - design.tsg;
        design = updatedims_interal_arm(design);
    end

    if design.tc > options.Max_tc
        % move the stator yoke outwards to reduce the size of the slot
        rshift = (design.tc - options.Max_tc);
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        design = updatedims_interal_arm(design);
    end

    if (design.ty / design.tm) > options.Max_tyVtm
        % move the stator yoke internal radius outwards to reduce the
        % thickness of the yoke
        rshift = design.ty - (design.tm * options.Max_tyVtm);
        design.Ryi = design.Ryi + rshift;
        design = updatedims_interal_arm(design);
    end

    if design.tm > options.Max_tm
        rshift = design.tm - options.Max_tm;
        design.tm = options.Max_tm;
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        design.Rtsb = design.Rtsb + rshift;
        design.Rtsg = design.Rtsg + rshift;
        design.Rao = design.Rao + rshift;
        design.Rmi = design.Rmi + rshift;
        design = updatedims_interal_arm(design);
    end

    if design.tsb > 0 && (design.tsg < design.tsb)

        x = ((design.thetac - design.thetasg)/2) * (design.Rao - design.tsb);
        y = design.tsb - design.tsg;

        tsbangle = rad2deg(atan( y / x ));

        if design.tsg < 1e-5
            x = ((design.thetac - design.thetasg)/2) * (design.Rao - design.tsb);
            y = design.tsb;
            tsgangle = rad2deg(atan( y / x ));
        else
            tsgangle = inf;
        end

        if tsbangle < 15 || tsgangle < 15

            rshift = design.tsb;
            design.tsb = 0;
            design.tsg = 0;
            design.Ryi = design.Ryi + rshift;
            design.Ryo = design.Ryo + rshift;
            design.Rci = design.Ryo;
            design.Rco = design.Rco + rshift;
            design.Rao = design.Rco;
            design.Rtsb = design.Rco;
            design.Rtsg = design.Rco;

            design = updatedims_interal_arm(design);
        end

    end

    if design.g < options.Min_g
        % increase the outer diameter
        rshift = (options.Min_g - design.g);
        design.Rmi = design.Rmi + rshift;
        design.Rmo = design.Rmo + rshift;
        design.Rbi = design.Rbi + rshift;
        design.Rbo = design.Rbo + rshift;
        design = updatedims_interal_arm(design);
    end
        
end


function design = updatedims_interal_arm(design)

    % some additional radial variables
    design.Rco = design.Rtsb;
    design.Rci = design.Ryo;
    design.Rbi = design.Rmo;

    % lengths in radial direction
    design.ty = design.Ryo - design.Ryi;
    design.tc = design.Rco - design.Rci;
    design.tsb = design.Rao - design.Rtsb;
    design.g = design.Rmi - design.Rao;
    design.tm = design.Rmo - design.Rmi;
    design.tbi = design.Rbo - design.Rbi;

    % the shoe tip length
    design.Rtsg = design.Rao - design.tsg;

    % mean radial position of magnets
    design.Rmm = mean([design.Rmo, design.Rmi]);
    design.Rcm = mean([design.Rci, design.Rco]);
    design.Rbm = mean([design.Rbo, design.Rbi]);
    design.Rym = mean([design.Ryi, design.Ryo]);

end


% function design = recalculateratios_internal_arm(design)
% % recalculates the design ratios of the slotted torus machine from the
% % dimensions
% 
%     design.RmoVRbo = design.Rmo / design.Rbo;
%     design.RmiVRmo = design.Rmi / design.Rmo;
%     design.RaoVRmi = design.Rao / design.Rmi;
%     design.RtsbVRao = design.Rtsb / design.Rao;
%     design.RtsgVRao = design.Rtsg / design.Rao;
%     design.RyoVRtsb = design.Ryo / design.Rtsb;
%     design.RyiVRyo = design.Ryi / design.Ryo;
%     design.thetamVthetap = design.thetam / design.thetap;
%     design.thetacVthetas = design.thetac / design.thetas;
%     design.thetasgVthetac = design.thetasg / design.thetac;
%     design.lsVtm = design.ls / design.tm;
% 
% end



