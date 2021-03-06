function [design, simoptions] = chrom2design_RADIAL_SLOTTED(simoptions, Chrom, varargin)
% converts a chromosomal representation of a slotted radial flux machine to
% a full machine design in preparation for simulation
%
% Syntax
%
% [design, simoptions] = chrom2design_RADIAL_SLOTTED(simoptions, Chrom, 'Parameter', Value)
%
%

% Copyright 2012-2015 Richard Crozier


    % Default design parameters
    
    % number of Phases
    options.Phases = 3;
    % number of coils per pole and phase
    options.qc = fr(3,3);
    options.yd = 4;
    options.UseResistanceRatio = true;
    % grid resistance to phase resistance ratio
    options.RlVRp = 10;
    options.LoadResistance = 1.0;
    % ratio of mid slot height to slot base size
    options.tc2Vtc1 = 0.1;
    % coil fill factor
    options.CoilFillFactor = 0.65;
    % default number of parallel strands in wire making up one turn
    options.NStrands = 1;
    % branch factor, determines number of parallel and series coils
    options.BranchFac = 0;
    % stator type, determines if we have an outer facing or inner facing
    % stator
    options.ArmatureType = 'internal';
    % number of coil layers
    options.CoilLayers = 2;
    
    % Default constraints on geometry
    
    % maximum permitted radial coil height
    options.Max_tc = 0.2;
    options.Min_tc = [];
    % maximum permitted slot base height
    options.Max_tsb = 0.2;
    % maximum permitted radial magnet height
    options.Max_tm = 0.05;
    % maximum stack length
    options.Max_ls = 4;
%     % maximum ratio of ty to tm
%     options.Max_tyVtm = inf;
%     % max ratio of tbi to tm
%     options.Max_tbiVtm = inf;
    % max permitted ratio of shoe base height to total slot height
    options.Max_tsbVtc1 = 0.9;
    % minimum permitted air gap
    options.Min_g = 0.5/1000;

    
    % parse the input options, replacing defaults
    options = parseoptions(options, varargin);
    
    % copy the design parameter options into the appropriate places in the
    % design structure
    design.ArmatureType = options.ArmatureType;
    design.CoilFillFactor = options.CoilFillFactor;
    design.NStrands = options.NStrands;
    design.Phases = max(1, round(options.Phases));
    design.qc = options.qc;
    design.yd = options.yd;
    if options.UseResistanceRatio
        design.RlVRp = options.RlVRp;
    else
        design.LoadResistance = options.LoadResistance;
    end
    design.CoilLayers = options.CoilLayers;
    
    % set a minimum wire diameter of 0.5mm, if not already set
    simoptions = setfieldifabsent(simoptions, ...
                    'MinStrandDiameter',  0.5/1000);
    
    % set default behaviour regarding whether to allow wire diamters which
    % can't fit through the slot opening. By default this is prevented.
	simoptions = setfieldifabsent(simoptions, ...
                    'PreventStrandDiameterGreaterThanSlotOpening',  true);
    
    if strcmp(design.ArmatureType, 'external')

        design = chrom2design_external_arm (design, simoptions, Chrom, options);
        
        Rstatorsurface = design.Rai;

    elseif strcmp(design.ArmatureType, 'internal')

        design = chrom2design_internal_arm (design, simoptions, Chrom, options);
        
        Rstatorsurface = design.Rao;

    end
    
    % prevent too wide slots
    % first get line equation of slot side
    m = ((design.thetacg - design.thetacy)/2) / (design.tc(1) - design.tc(2));
    % get intercept with the yoke
    cy = design.thetacg/2 - m * design.tc(1);
    
    if cy > ((design.thetas-2e-5) / 2)
        % the slots will overlap  each other in this case
        
        % find the slope which means slots do not overlap
        m = ((design.thetacg - (design.thetas-2e-5))/2) / design.tc(1);
        % make the intercept thetas at the coil base end (inner yoke
        % surface)
        cy = (design.thetas-2e-5) / 2;
        design.thetacy = 2 * (m .* design.tc(2) + cy);
        % update ratios etc
        design.thetacyVthetas = design.thetacy / design.thetas;
        design.thetac = [design.thetacg, design.thetacy];
        
    end
    
    % now prevent overlap at the shoe curve region
    
    % get width at the shoe base radial position
    cs = m * (design.tc(1) + (design.tsb-design.tsg)/2) + cy;
    
    if cs > ((design.thetas-2e-5) / 2)
        % the slots will overlap  each other in this case
        
        % find the slope which means slots do not overlap
        m = ((design.thetas-2e-5)/2 - design.thetacy/2) / (design.tc(1) - design.tc(2) + (design.tsb-design.tsg)/2);
        % make the intercept thetas at the slot opening end
        cs = (design.thetacy/2) - m * (design.tc(2));
        design.thetacg = 2 * (m .* design.tc(1) + cs);
        % update ratios etc
        design.thetacgVthetas = design.thetacg / design.thetas;
        design.thetac = [design.thetacg, design.thetacy];
        
    end
    
    
	if simoptions.PreventStrandDiameterGreaterThanSlotOpening
        % check the wire can fit through the slot opening, taing action to
        % allow it to if required, and setting the max possible wire size
        % to an appropriate size
        if (0.5*design.thetasg*Rstatorsurface) > simoptions.MinStrandDiameter
            % set a max wire strand diameter which allow the wire to fit
            % through the slot opening
            simoptions = setfieldifabsent (simoptions, ...
                            'MaxStrandDiameter', 0.5*design.thetasg*Rstatorsurface);
        else
            % the slot opening is already smaller than the smallest possible
            % wire size, therefore we must make the slot opening just big
            % enough to allow at least the minimum wire size through, and set
            % an appropriate max wire size
            design.thetasg = 2*simoptions.MinStrandDiameter / Rstatorsurface;
            design.thetasgVthetacg = design.thetasg / design.thetacg;
            % check the slot opening is not greater than the coil width at
            % the opening end
            if design.thetasgVthetacg >= 1
                % if it is, set it to the max possible, there is not much
                % more that can be done short of changing the whole design
                % of the coil. Should this prove to be an issue, an
                % optimisation penalty can be introduced for this case.
                design.thetasg = ((design.thetacg*Rstatorsurface) - (2*1e-5)) / Rstatorsurface;
                design.thetasg = max (0,design.thetasg);
                design.thetasgVthetacg = design.thetasg / design.thetacg;
%                 design.thetasg = design.thetasgVthetacg * design.thetacg;
            end

            simoptions = setfieldifabsent (simoptions, ...
                            'MaxStrandDiameter', simoptions.MinStrandDiameter*1.001);
        end
	end
    
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
    
    design.Hc = design.tc(1) + design.tsb;
    
    if strcmp(design.ArmatureType, 'external')
        design.Wc = mean([design.thetacg * design.Rci, design.thetacy * design.Rco]);
    elseif strcmp(design.ArmatureType, 'internal')
        design.Wc = mean([design.thetacg * design.Rco, design.thetacy * design.Rci]);
    end
    
    design = preprocsystemdesign_RADIAL(design, simoptions);
    
end

function design = common_setup_1 (design, simoptions, Chrom, options)
% common setup stuff, getting common variables out of Chrom etc

    tyVtm = Chrom(2);
    tcVMax_tc = Chrom(3);
    tsbVMax_tsb = Chrom(4);
    design.tsgVtsb = Chrom(5);
    g = Chrom(6);
    tmVMax_tm = Chrom(7);
    tbiVtm = Chrom(8);
    design.thetamVthetap = Chrom(9);
    design.thetacgVthetas = Chrom(10);
    design.thetacyVthetas = Chrom(11);
    design.thetasgVthetacg = Chrom(12);
    lsVMax_ls = Chrom(13);
    design.NBasicWindings = round(Chrom(14));
    design.DcAreaFac = Chrom(15);
    design.BranchFac = Chrom(16);
    
    if numel(Chrom) > 16
        design.MagnetSkew = Chrom(17);
    end
    
    design.ls = lsVMax_ls * options.Max_ls;
    
    design.g = g;
    design.tc(1) = tcVMax_tc * options.Max_tc;
    
    design.tm = tmVMax_tm * options.Max_tm;
    if design.tm < 1e-3
        design.tm = 1e-3;
    end
    
    design.tsb = tsbVMax_tsb * options.Max_tsb;
%     design.tsg = design.tsgVtsb * design.tsb;

    design.tbi = tbiVtm * design.tm;
    if design.tbi < 1e-3
        design.tbi = 1e-3;
    end
    
    design.ty = tyVtm * design.tm;
    if design.ty < 1e-3
        design.ty = 1e-3;
    end
    
end


function design = chrom2design_external_arm (design, simoptions, Chrom, options)


    % get external arm specific variabes from chrom, i.e. Ryo
    design.Ryo = Chrom(1);

    % get the rest of the common variable out of Chrom
    design = common_setup_1 (design, simoptions, Chrom, options);
    
    design.Ryi = design.Ryo - design.ty;
    design.RyiVRyo = design.Ryi / design.Ryo;
    design.Rtsb = design.Ryi - design.tc(1);
    design.RtsbVRyi = design.Rtsb / design.Ryi;
    design.Rai = design.Rtsb - design.tsb;
    design.RaiVRtsb = design.Rai / design.Rtsb;
    design.Rmo = design.Rai - design.g;
    design.RmoVRai = design.Rmo / design.Rai;
    design.Rmi = design.Rmo - design.tm;
    design.RmiVRmo = design.Rmi / design.Rmo;
    design.Rbi = design.Rmi - design.tbi;
    design.RbiVRmi = design.Rbi / design.Rmi;
    design.lsVtm = design.ls / design.tm;
    
    if design.Rbi < 1e-4;
        if design.Rbi < 0
            rshift = -design.Rbi + 1e-4;
        else
            rshift = 1e-4;
        end
        if design.Rbi < 0
            rshift = rshift + abs(design.Rbi);
        end
        design.Rbi = design.Rbi + rshift;
        design.Rmi = design.Rmi + rshift;
        design.Rmo = design.Rmo + rshift;
        design.Rai = design.Rai + rshift;
        design.Rtsb = design.Rtsb + rshift;
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        design.RyiVRyo = design.Ryi / design.Ryo;
        design.RtsbVRyi = design.Rtsb / design.Ryi;
        design.RaiVRtsb = design.Rai / design.Rtsb;
        design.RmoVRai = design.Rmo / design.Rai;
        design.RmiVRmo = design.Rmi / design.Rmo;
        design.RbiVRmi = design.Rbi / design.Rmi;
    end

    design = completedesign_RADIAL_SLOTTED(design, simoptions);
    
    % check if the shoe base is too big relative to the coil body height
    if (design.tsb > 0) && (design.tsb / design.tc(1)) > options.Max_tsbVtc1
        % shift the shoe base inward
        rshift = (design.tsb - (design.tc(1)*options.Max_tsbVtc1));
        design.Rtsb = design.Rtsb - rshift;
        design.tsb = design.tc(1)*options.Max_tsbVtc1;
        % recalculate the shoe gap size
        design.tsg = design.tsb * design.tsgVtsb;
        design.Rtsg = design.Rai + design.tsg;
        design = updatedims_exteral_arm(design);
    end
    
    % check if the coil slot height is greater than the maximum allowed
    if design.tc(1) > options.Max_tc
        % move the stator yoke inwards to reduce the size of the slot
        rshift = (design.tc(1) - options.Max_tc);
        design.Ryi = design.Ryi - rshift;
        design.Ryo = design.Ryo - rshift;
        design = updatedims_exteral_arm(design);
    end
    
    if isempty (options.Min_tc)
        options.Min_tc = 0.05 * mean(design.thetac) * design.Rcm;
        
        if isfield (design, 'CoilInsulationThickness')
            options.Min_tc = options.Min_tc + 3*design.CoilInsulationThickness;
        end
    end
    
    % check if the coil slot height is smaler than the minimum allowed
    if design.tc(1) < options.Min_tc
        % move the stator yoke outwards to increase the size of the slot
        rshift = (options.Min_tc - design.tc(1));
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        design = updatedims_exteral_arm(design);
    end
    
%     % check if the yoke thickness is too big relative to the magnet thickness
%     if (design.ty / design.tm) > options.Max_tyVtm
%         % move the stator yoke internal radius outwards to reduce the
%         % thickness of the yoke
%         rshift = design.ty - (design.tm * options.Max_tyVtm);
%         design.Ryo = design.Ryo - rshift;
%         
%         design = updatedims_exteral_arm(design);
%     end
%     
%     % check if the back iron thickness is too big relative to the magnet
%     % thickness
%     if (design.tbi / design.tm) > options.Max_tbiVtm
%         % move the stator yoke internal radius inwards to reduce the
%         % thickness of the yoke
%         rshift = design.tbi - (design.tm * options.Max_tbiVtm);
%         design.Rbi = design.Rbi + rshift;
%         design = updatedims_exteral_arm(design);
%     end
%     
%     % check if the magnet thickness is greater than the maximum allowed
%     if design.tm > options.Max_tm
%         rshift = design.tm - options.Max_tm;
%         design.tm = options.Max_tm;
%         design.Rmi = design.Rmi + rshift;
%         design.Rbi = design.Rbi + rshift;
%         design = updatedims_exteral_arm(design);
%     end

    % check if the configuration of the shoe will cause too small triangles
    % to be created in the mesh
    if design.tsb > 0 && (design.tsg < design.tsb)
        
%         x = ((design.thetac(1) - design.thetasg)/2) * design.Rtsb;
%         y = design.tsb - design.tsg;
% 
%         tsbangle = rad2deg(atan( y / x ));

        if design.tsg < 1e-5
            x = ((design.thetacg - design.thetasg)/2) * design.Rtsb;
            y = design.tsb;
            tsgangle = rad2deg(atan( y / x ));
        else
            tsgangle = inf;
        end

        if tsgangle < 15
            % remove the shoe altogether
            design.tsb = 0;
            design.tsg = 0;
            design.Rtsb = design.Rci;
            design.Rai = design.Rtsb;

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
    
    % set the size of the slot base
    design.tc(2) = design.tc(1) * options.tc2Vtc1;
    design.Rcb = design.Rco - design.tc(2);
    
    % check the angle of slot straight side is not too small
    slotsideangle = atan ((design.tc(1) - design.tc(2)) ...
                                    / abs(((design.thetacg*design.Rci) - (design.thetacy*design.Rco))/2));
                               
    if slotsideangle < deg2rad (5)
        % make the slot height bigger to increase the angle
        newtc = ( tan (deg2rad (5)) ...
                           * abs( ((design.thetacg*design.Rci) - (design.thetacy*design.Rco))/2) ) ...
                         / (1 - options.tc2Vtc1 );
        
        rshift = newtc - design.tc(1);
        design.tc(1) = newtc;
        design.tc(2) = design.tc(1) * options.tc2Vtc1;
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        design.Rcb = design.Ryi - design.tc(2);
        
        design = updatedims_exteral_arm(design);
    end
    
    % check the angle of the base is not too small
    slotbaseangle = 2 * (atan ((design.thetacy/2) * (design.Rco - design.tc(2)) / design.tc(2)));
    minangle = 10;
    if slotbaseangle < deg2rad (minangle)
        % move the slot base to make the angle at least 10 degrees
        tau_cy = design.Rcb * design.thetacy;
        
        newtc2 = tau_cy/2 / tan(deg2rad (minangle/2));
        
        design.tc(2) = newtc2;
        design.Rcb = design.Ryi - design.tc(2);
        
        design = updatedims_exteral_arm(design);
    end
        
end

function design = updatedims_exteral_arm (design)

    % some additional radial variables
    design.Rci = design.Rtsb;
    design.Rco = design.Ryi;
    design.Rbo = design.Rmi;

    % lengths in radial direction
    design.ty = design.Ryo - design.Ryi;
    design.tc(1) = design.Rco - design.Rci;
    if isfield (design, 'Rcb')
        design.tc(2) = design.Rco - design.Rcb;
    end
    design.tsb = design.Rtsb - design.Rai;
    design.g = design.Rai - design.Rmo;
    design.tm = design.Rmo - design.Rmi;
    design.tbi = design.Rbo - design.Rbi;

    % the shoe tip length
    design.Rtsg = design.Rai + design.tsg;

    % mean radial position of magnets
    design.Rmm = mean([design.Rmo, design.Rmi]);
    design.Rcm = mean([design.Rci, design.Rco]);
    design.Rbm = mean([design.Rbo, design.Rbi]);
    design.Rym = mean([design.Ryi, design.Ryo]);
    
    % update the ratios
    design.RyiVRyo = design.Ryi / design.Ryo;
    design.RtsbVRyi = design.Rtsb / design.Ryi;
    design.RaiVRtsb = design.Rai / design.Rtsb;
    design.RmoVRai = design.Rmo / design.Rai;
    design.RmiVRmo = design.Rmi / design.Rmo;
    design.RbiVRmi = design.Rbi / design.Rmi;
    design.tsgVtsb = design.tsg / design.tsb;

    % thetap and thetas are calculated in completedesign_RADIAL
    design.thetamVthetap = design.thetam / design.thetap;
    design.thetacgVthetas = design.thetacg / design.thetas;
    design.thetacyVthetas = design.thetacy / design.thetas;
    design.thetasgVthetacg = design.thetasg / design.thetacg;
    design.lsVtm = design.ls / design.tm;
    design.thetac = [design.thetacg, design.thetacy];
    
end


function design = chrom2design_internal_arm (design, simoptions, Chrom, options)

    % convert inerna specific machine ratios to actual dimensions
    design.Rbo = Chrom(1);

    % get the rest of the common ratios etc.
    design = common_setup_1 (design, simoptions, Chrom, options);
    
    design.Rmo = design.Rbo - design.tbi;
    design.Rmi = design.Rmo - design.tm;
    design.Rao = design.Rmi - design.g;
    design.Rtsb = design.Rao - design.tsb;
    design.Ryo = design.Rtsb - design.tc(1);
    design.Ryi = design.Ryo - design.ty;
    
    design.RmoVRbo = design.Rmo / design.Rbo;
    design.RmiVRmo = design.Rmi / design.Rmo;
    design.RaoVRmi = design.Rao / design.Rmi;
    design.RtsbVRao = design.Rtsb / design.Rao;
    design.RyoVRtsb = design.Ryo / design.Rtsb;
    design.RyiVRyo = design.Ryi / design.Ryo;
    design.lsVtm = design.ls / design.tm;
    
    % check if the dimensions result in a design with too small an inner
    % radius
    if design.Ryi < 1e-4;
        if design.Ryi < 0
            rshift = -design.Ryi + 1e-4;
        else
            rshift = 1e-4;
        end
        if design.Ryi < 0
            rshift = rshift + abs(design.Ryi);
        end
        design.Rbo = design.Rbo + rshift;
        design.Rmo = design.Rmo + rshift;
        design.Rmi = design.Rmi + rshift;
        design.Rao = design.Rao + rshift;
        design.Rtsb = design.Rtsb + rshift;
        design.Ryo = design.Ryo + rshift;
        design.Ryi = design.Ryi + rshift;
        
        design.RmoVRbo = design.Rmo / design.Rbo;
        design.RmiVRmo = design.Rmi / design.Rmo;
        design.RaoVRmi = design.Rao / design.Rmi;
        design.RtsbVRao = design.Rtsb / design.Rao;
        design.RyoVRtsb = design.Ryo / design.Rtsb;
        design.RyiVRyo = design.Ryi / design.Ryo;
%         design.tsgVtsb = design.tsg / design.tsb;
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

    % check for too big tooth shoe
    if (design.tsb > 0) && (design.tsb / design.tc(1)) > options.Max_tsbVtc1
        % shift the shoe base radial position outward
%         rshift = (design.tsb - (design.tc(1)*options.Max_tsbVtc1));
%         design.Rtsb = design.Rtsb + rshift;
        design.tsb = design.tc(1)*options.Max_tsbVtc1;
        design.Rtsb = design.Rao - design.tsb;
        % recalculate the shoe gap size
        design.tsg = design.tsb * design.tsgVtsb;
        design.Rtsg = design.Rao - design.tsg;
        design = updatedims_interal_arm(design);
    end

    % check if the coil slot height is greater than the maximum allowed
    if design.tc(1) > options.Max_tc
        % move the stator yoke outwards to reduce the size of the slot
        rshift = (design.tc(1) - options.Max_tc);
        design.tc(1) = options.Max_tc;
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        design = updatedims_interal_arm(design);
    end
    
    if isempty (options.Min_tc)
        options.Min_tc = 0.05 * mean(design.thetac) * design.Rcm;
        
        if isfield (design, 'CoilInsulationThickness')
            options.Min_tc = options.Min_tc + 3*design.CoilInsulationThickness;
        end
    end
    
    % check if the coil slot height is smaller than the minimum allowed
    if design.tc(1) < options.Min_tc
        % move the stator yoke inwards to increase the size of the slot
        rshift = (options.Min_tc - design.tc(1));
        
        if rshift >= design.Ryi
            % the amount we need to shift inwards is greater than the space
            % available, so we'll have to shift everything outwards a bit
            % to make the space
            rshift2 = design.Ryi - rshift + 1e-5;
        else
            rshift2 = 0;
        end
        
        % first shift yoke inwards by rshift
        design.Ryi = design.Ryi - rshift;
        design.Ryo = design.Ryo - rshift;
        
        % then shift everything outwards by rshift2
        design.Rbo = design.Rbo + rshift2;
        design.Rmo = design.Rmo + rshift2;
        design.Rmi = design.Rmi + rshift2;
        design.Rao = design.Rao + rshift2;
        design.Rtsb = design.Rtsb + rshift2;
        design.Ryo = design.Ryo + rshift2;
        design.Ryi = design.Ryi + rshift2;
        
        design = updatedims_interal_arm(design);
    end
    
%     % check if the yoke thickness is too big relative to the magnet thickness
%     if (design.ty / design.tm) > options.Max_tyVtm
%         % move the stator yoke internal radius outwards to reduce the
%         % thickness of the yoke
%         rshift = design.ty - (design.tm * options.Max_tyVtm);
%         design.Ryo = design.Ryo - rshift;
%         
%         design = updatedims_exteral_arm(design);
%     end
%     
%     % check if the back iron thickness is too big relative to the magnet
%     % thickness
%     if (design.tbi / design.tm) > options.Max_tbiVtm
%         % move the stator yoke internal radius inwards to reduce the
%         % thickness of the yoke
%         rshift = design.tbi - (design.tm * options.Max_tbiVtm);
%         design.Rbi = design.Rbi + rshift;
%         design = updatedims_exteral_arm(design);
%     end
%     
%     % check if the magnet thickness is greater than the maximum allowed
%     if design.tm > options.Max_tm
%         rshift = design.tm - options.Max_tm;
%         design.tm = options.Max_tm;
%         design.Rmi = design.Rmi + rshift;
%         design.Rbi = design.Rbi + rshift;
%         design = updatedims_exteral_arm(design);
%     end

    % check if the configuration of the shoe will cause too small triangles
    % to be created in the mesh
    if design.tsb > 0 && (design.tsg < design.tsb)
        
%         x = ((design.thetac(1) - design.thetasg)/2) * design.Rtsb;
%         y = design.tsb - design.tsg;
% 
%         tsbangle = rad2deg(atan( y / x ));

        if design.tsg < 1e-5
            x = ((design.thetacg - design.thetasg)/2) * design.Rtsb;
            y = design.tsb;
            tsgangle = rad2deg(atan( y / x ));
        else
            tsgangle = inf;
        end

        if tsgangle < 15
            % remove the shoe altogether
            design.tsb = 0;
            design.tsg = 0;
            design.Rtsb = design.Rco;
            design.Rao = design.Rtsb;

            design = updatedims_interal_arm(design);
        end

    end

    if design.g < options.Min_g
        % increase the outer diameter
        rshift = (options.Min_g - design.g);
        
        design.Rbo = design.Rbo + rshift;
        design.Rmo = design.Rmo + rshift;
        design.Rmi = design.Rmi + rshift;
        
        design = updatedims_interal_arm (design);
    end
    
    % set the size of the slot base
    design.tc(2) = design.tc(1) * options.tc2Vtc1;
    design.Rcb = design.Ryo + design.tc(2);
    
    % check the angle of slot straight side is not too small
    slotsideangle = atan ((design.tc(1) - design.tc(2)) ...
                                    / abs(((design.thetacg*design.Rco) - (design.thetacy*design.Rci))/2));
                               
    if slotsideangle < deg2rad (5)
        % make the slot height bigger to increase the angle
        newtc = ( tan (deg2rad (5)) ...
                           * abs( ((design.thetacg*design.Rco) - (design.thetacy*design.Rci))/2) ) ...
                         / (1 - options.tc2Vtc1 );
        
        rshift = newtc - design.tc(1);
        design.tc(1) = newtc;
        design.tc(2) = design.tc(1) * options.tc2Vtc1;
        
        if rshift >= design.Ryi
            % the amount we need to shift inwards is greater than the space
            % available, so we'll have to shift everything outwards a bit
            % to make the space
            rshift2 = design.Ryi - rshift;
        else
            rshift2 = 0;
        end
        
        % first shift yoke inwards by rshift
        design.Ryi = design.Ryi - rshift;
        design.Ryo = design.Ryo - rshift;
        
        % then shift everything outwards by rshift2
        design.Rbo = design.Rbo + rshift2;
        design.Rmo = design.Rmo + rshift2;
        design.Rmi = design.Rmi + rshift2;
        design.Rao = design.Rao + rshift2;
        design.Rtsb = design.Rtsb + rshift2;
        design.Ryo = design.Ryo + rshift2;
        design.Ryi = design.Ryi + rshift2;
        
        design.Rcb = design.Ryo + design.tc(2);
        
        design = updatedims_interal_arm (design);
        
    end
    
    % check the angle of the base is not too small
    slotbaseangle = 2 * (atan ((design.thetacy/2) * (design.Ryo + design.tc(2)) / design.tc(2)));
    minangle = 10;
    if slotbaseangle < deg2rad (minangle)
        % move the slot base to make the angle at least 10 degrees
        tau_cy = design.Rcb * design.thetacy;
        
        newtc2 = tau_cy/2 / tan(deg2rad (minangle/2));
        
        design.tc(2) = newtc2;
        design.Rcb = design.Ryo + design.tc(2);
        
        design = updatedims_interal_arm (design);
    end
    
    
end


function design = updatedims_interal_arm (design)

    % some additional radial variables
    design.ty = design.Ryo - design.Ryi;
    design.tc = design.Rtsb - design.Ryo;
    design.tsb = design.Rao - design.Rtsb;
    design.g = design.Rmi - design.Rao;
    design.tm = design.Rmo - design.Rmi;
    design.tbi = design.Rbo - design.Rmo;

    design.Rco = design.Rtsb;
    design.Rci = design.Ryo;
    design.Rbi = design.Rmo;
    design.Rtsg = design.Rao - design.tsg;

    if isfield (design, 'Rcb')
        design.tc(2) = design.Rcb - design.Ryo;
        design.RcbVRtsb = design.Rcb / design.Rtsb;
    end

    % mean radial position of magnets
    design.Rmm = mean([design.Rmo, design.Rmi]);
    design.Rcm = mean([design.Rci, design.Rco]);
    design.Rbm = mean([design.Rbo, design.Rbi]);
    design.Rym = mean([design.Ryi, design.Ryo]);
    
    % complete the ratios
    design.RmoVRbo = design.Rmo / design.Rbo;
    design.RmiVRmo = design.Rmi / design.Rmo;
    design.RaoVRmi = design.Rao / design.Rmi;
    design.RtsbVRao = design.Rtsb / design.Rao;
    design.RyoVRtsb = design.Ryo / design.Rtsb;
    design.RyiVRyo = design.Ryi / design.Ryo;
    design.tsgVtsb = design.tsg / design.tsb;

    design.thetamVthetap = design.thetam / design.thetap;
    design.thetacgVthetas = design.thetacg / design.thetas;
    design.thetacyVthetas = design.thetacy / design.thetas;
    design.thetasgVthetacg = design.thetasg / design.thetacg;
    design.lsVtm = design.ls / design.tm;

end
