function design = completedesign_RADIAL_SLOTTED(design, simoptions)
% converts a minimal design specification to a complete design suitable for
% use by simfun_RADIAL_SLOTTED
%
% Syntax
%
% design = completedesign_RADIAL_SLOTTED(design, simoptions)
%
% Description
%
% completedesign_RADIAL_SLOTTED takes a minimal design structure describing
% a slotted radial flux permanent magnet machine design and completes it by
% calculating various dimensions and parameters and properties of the
% machine windings etc. The design dimensions can be specified either as
% dimensionless ratios or actual dimensions. All variables are supplied as
% fields in a machine design structure.
%
% The design can be for either an internal or external armature. This is
% specified in the field 'ArmatureType' which must contain a string, either
% 'internal' or 'external'. Any unambiguous substring is also acceptable,
% e.g 'e' or'i', or 'ext', or 'in'.
% 
% In general, all dimensions which refer to a radial measurement from the
% center of the machine are prefixed with the capital letter 'R'.
%
% For an INTERNAL ARMATURE machine, the design structure must also contain
% either all the fields:
%
%    RmoVRbo - 
%    RmiVRmo - 
%    RsoVRmi -  
%    RtsbVRao - 
%    RyoVRtsb - 
%    RyiVRyo -  
%    tsgVtsb -  
%    thetamVthetap - 
%    thetacVthetas -  
%    thetasgVthetac -  
%    lsVtm - 
%
% or all the fields:
%
%    Rbo - radial distance to outer back iron surface
%    Rmo - radial distance to outer magnet surface
%    Rmi - radial distance to inner magnet surface
%    Rao - radial distance to 
%    Rtsb - radial distance to 
%    Ryo -  radial distance to 
%    Ryi - radial distance to 
%    tsg - 
%    thetam - 
%    thetac - 
%    thetasg -  
%    ls - 
%
% or all the fields
%
%    Rbo - 
%    g - 
%    ty - 
%    tm - 
%    tc - 
%    tsb - 
%    tbi - 
%    tsg - 
%    thetam - 
%    thetac - 
%    thetasg -  
%    ls - 
%
% For an EXTERNAL ARMATURE machine, the design structure must also contain
% either all the fields:
%
%    RyiVRyo - 
%    RtsbVRyi - 
%    RaiVRtsb - 
%    RmoVRai - 
%    RmiVRmo - 
%    RbiVRmi - 
%    tsgVtsb -  
%    thetamVthetap - 
%    thetacVthetas -  
%    thetasgVthetac -  
%    lsVtm - 
% 
% or all the fields:
%
%    Ryo - 
%    Ryi - 
%    Rtsb - 
%    Rai - 
%    Rmi - 
%    Rmo -  
%    Rbi - 
%    tsg - 
%    thetam - 
%    thetasg -  
%    ls -  
%
% or all the fields:
%
%    Ryo - 
%    g - 
%    ty - 
%    tm - 
%    tc - 
%    tsb - 
%    tbi - 
%    tsg - 
%    thetam - 
%    thetasg -  
%    ls - 
%
% This completes the specification of the physical dimentions of the
% armature and field.
%
% In addition, a winding specification must be supplied. The winding is
% described using the following variables:
%
%  yp - Average coil pitch as defined by (Qs/Poles)
%  yd - Actual coil pitch as defined by round(yp) +/- k
%  Qs  -  total number of stator slots in machine
%  Qc  -  total number of winding coils in machine 
%  q  -  number of slots per pole and phase
%  qn  -  numerator of q
%  qd  -  denominator of q
%  qc - number of coils per pole and phase
%  qcn  -  numerator of qc
%  qcd  -  denominator of qc
%  Qcb - basic winding (the minimum number of coils required to make up a 
%    repetitive segment of the machine that can be modelled using symmetry)
%  pb - the number of poles corresponding to the basic winding in Qcb
%
% This pole/slot/coil/winding terminology is based on that presented in
% [1].
%
% Machine windings can be single or double layered, in which case:
%
% Single layer
%   q = 2qc
%   Qs = 2Qc
% Double layer
%   q = qc
%   Qs = Qc
%
% To specify a winding, the 'minimum spec' that must be provided is based on
% a combination of some or all of the following variables:
%
%  Phases - The number of phases in the machine
%  Poles - The number of magnetic poles in the machine
%  NBasicWindings - the number of basic winding segments in the machine
%  qc - number of coils per pole and phase (as a fraction object)
%  Qc - total number of coils (in all phases) in the machine
%
% Any of the following combinations may be supplied to specify the winding:
%
%   Poles, Phases, Qc
%   Poles, Phases, qc
%   qc, Phases, NBasicWindings
%
% These variables must be provided as fields in the design structure. If
% 'qc' is supplied, it must be an object of the class 'fr'. This is a class
% designed for handling fractions. See the help for the ''fr'' class for
% further information.
%
% Example:
%
% 
%
% See also: fr.m, completedesign_RADIAL.m, completedesign_ROTARY.m
%
% [1] J. J. Germishuizen and M. J. Kamper, "Classification of symmetrical
% non-overlapping three-phase windings," in The XIX International
% Conference on Electrical Machines - ICEM 2010, 2010, pp. 1-6.
%

    if nargin < 2
        simoptions = struct ();
    end

    % perform processing common to all radial machines, primarily the
    % winding specification
    design = completedesign_RADIAL(design, simoptions);
    
    % calculate the various dimensions from the supplied ratios depending
    % on the specified stator type
    if strncmpi(design.ArmatureType, 'external', 1)
        
        design = completeexternal (design);
        
    elseif strncmpi(design.ArmatureType, 'internal', 1)
        
        design = completeinternal (design);
        
    else
        error('Unrecognised armature type.')
    end
        
    % mean radial position of magnets and coils
    design.Rmm = mean([design.Rmo, design.Rmi]);
    design.Rcm = mean([design.Rci, design.Rco]);
    design.Rbm = mean([design.Rbo, design.Rbi]);
    design.Rym = mean([design.Ryi, design.Ryo]);
    
    [design.NCoilsPerPhase,~] = rat(fr(design.Qc,design.Phases));
    
    % slot pitch at the mean slot height
    design.tausm = design.thetas * design.Rcm;
    
end

function design = completeexternal (design)

                
    ratiofields = { 'RyiVRyo';
                    'RtsbVRyi';
                    'RaiVRtsb';
                    'RmoVRai';
                    'RmiVRmo';
                    'RbiVRmi';
                    'tsgVtsb'; 
                    'thetamVthetap';
                    'thetacVthetas'; 
                    'thetasgVthetac'; 
                    'lsVtm'; };
                    
    dimfields1 = { 'Ryo';
                   'Ryi';
                   'Rtsb';
                   'Rai';
                   'Rmi';
                   'Rmo'; 
                   'Rbi';
                   'tsg';
                   'thetam';
                   'thetac';
                   'thetasg'; 
                   'ls'; };

    dimfields2 = { 'Ryo';
                   'g';
                   'ty';
                   'tm';
                   'tc';
                   'tsb';
                   'tbi';
                   'tsg';
                   'thetam';
                   'thetac';
                   'thetasg'; 
                   'ls'; };

    if all(isfield(design, ratiofields))
        % convert the ratio set to actual dimensions
        design = structratios2structvals(design, ratiofields(1:6), 'Ryo', 'V');

        % process the angular ratios, thetas is calculated in
        % completedesign_RADIAL.m based on the number of slots
        design.thetam = design.thetamVthetap * design.thetap;
        design.thetac = design.thetacVthetas * design.thetas;
        design.thetasg = design.thetasgVthetac * design.thetac;
        % the shoe tip length
        design.tsb = design.Rai - design.Rtsb;
        design.tsg = design.tsgVtsb * design.tsb;

        design.Rco = design.Ryo;
        design.Rci = design.Rtsb;
        design.Rbo = design.Rmi;
        design.Rtsg = design.Rai + design.tsg;

        % calculate the lengths
        design.ty = design.Ryo - design.Ryi;
        design.tc = design.Rco - design.Rci;
        design.tsb = design.Rtsb - design.Rai;
        design.g = design.Rai - design.Rmi;
        design.tm = design.Rmi - design.Rmo;
        design.tbi = design.Rbi - design.Rbo;

        % finally calculate the stack length
        design.ls = design.lsVtm * design.tm;

    elseif all(isfield(design, dimfields1))
        % The dimensions are present already, specified using the
        % radial dimensions, calculate the lengths
        design.ty = design.Ryo - design.Ryi;
        design.tsb = design.Rtsb - design.Rai;
        design.g = design.Rai - design.Rmo;
        design.tm = design.Rmo - design.Rmi;
        design.tbi = design.Rmi - design.Rbi;

        design.Rco = design.Ryi;
        design.Rci = design.Rtsb;
        design.Rbo = design.Rmi;
        design.Rtsg = design.Rai + design.tsg;
        
        design.tc = design.Rco - design.Rci;
        
        % complete the ratios
        design.RyiVRyo = design.Ryi / design.Ryo;
        design.RtsbVRyi = design.Rtsb / design.Ryi;
        design.RaiVRtsb = design.Rai / design.Rtsb;
        design.RmoVRai = design.Rmo / design.Rai;
        design.RmiVRmo = design.Rmi / design.Rmo;
        design.RbiVRmi = design.Rbi / design.Rmi;
        design.tsgVtsb = design.tsg / design.tsb;
        
        % thetap and thetas are calculated in completedesign_RADIAL
        design.thetamVthetap = design.thetam / design.thetap;
        design.thetacVthetas = design.thetac / design.thetas;
        design.thetasgVthetac = design.thetasg / design.thetac;
        design.lsVtm = design.ls / design.tm;

    elseif all(isfield(design, dimfields2))
        
        % The dimensions are present already, specified using lengths,
        % calculate the radial dimensions
        design.Ryi = design.Ryo - design.ty;
        design.Rtsb = design.Ryi - design.tc;
        design.Rai = design.Rtsb - design.tsb;
        design.Rmo = design.Rai - design.g;
        design.Rmi = design.Rmo - design.tm;
        design.Rbi = design.Rmi - design.tbi;
        
        design.Rco = design.Ryi;
        design.Rci = design.Rtsb;
        design.Rbo = design.Rmi;
        design.Rtsg = design.Rai + design.tsg;
        
        % complete the ratios
        design.RyiVRyo = design.Ryi / design.Ryo;
        design.RtsbVRyi = design.Rtsb / design.Ryi;
        design.RaiVRtsb = design.Rai / design.Rtsb;
        design.RmoVRai = design.Rmo / design.Rai;
        design.RmiVRmo = design.Rmi / design.Rmo;
        design.RbiVRmi = design.Rbi / design.Rmi;
        design.tsgVtsb = design.tsg / design.tsb;
        
        % thetap and thetas are calculated in completedesign_RADIAL
        design.thetamVthetap = design.thetam / design.thetap;
        design.thetacVthetas = design.thetac / design.thetas;
        design.thetasgVthetac = design.thetasg / design.thetac;
        design.lsVtm = design.ls / design.tm;

    else
        % something's missing
        error( 'RENEWNET:pmmachines:slottedradspec', ...
               'For a slotted radial flux design with external armature you must have the\nfields %s OR %s OR %s in the design structure.', ...
               sprintf('%s, ', ratiofields{:}), ...
               sprintf('%s, ', dimfields1{:}), ...
               sprintf('%s, ', dimfields2{:}))
    end

end


function design = completeinternal (design)

    ratiofields = { 'RmoVRbo';
                    'RmiVRmo';
                    'RaoVRmi'; 
                    'RtsbVRao';
                    'RyoVRtsb';
                    'RyiVRyo'; 
                    'tsgVtsb'; 
                    'thetamVthetap';
                    'thetacVthetas'; 
                    'thetasgVthetac'; 
                    'lsVtm'; };
                    
    dimfields1 = { 'Rbo';
                   'Rmo';
                   'Rmi';
                   'Rao';
                   'Rtsb';
                   'Ryo'; 
                   'Ryi';
                   'tsg';
                   'thetam';
                   'thetac';
                   'thetasg'; 
                   'ls'; };

    dimfields2 = { 'Rbo';
                   'g';
                   'ty';
                   'tm';
                   'tc';
                   'tsb';
                   'tbi';
                   'tsg';
                   'thetam';
                   'thetac';
                   'thetasg'; 
                   'ls'; };

    if all(isfield(design, ratiofields))
        % convert the ratio set to actual dimensions
        design = structratios2structvals(design, ratiofields(1:6), 'Rbo', 'V');

        % process the angular ratios, thetas is calculated in
        % completedesign_RADIAL.m based on the number of slots
        design.thetam = design.thetamVthetap * design.thetap;
        design.thetac = design.thetacVthetas * design.thetas;
        design.thetasg = design.thetasgVthetac * design.thetac;
        % the shoe tip length
        design.tsb = design.Rao - design.Rtsb;
        design.tsg = design.tsgVtsb * design.tsb;

        design.Rco = design.Rtsb;
        design.Rci = design.Ryo;
        design.Rbi = design.Rmo;
        design.Rtsg = design.Rao - design.tsg;

        % calculate the lengths
        design.ty = design.Ryo - design.Ryi;
        design.tc = design.Rco - design.Rci;
        design.tsb = design.Rao - design.Rtsb;
        design.g = design.Rmi - design.Rao;
        design.tm = design.Rmo - design.Rmi;
        design.tbi = design.Rbo - design.Rbi;

        % finally calculate the stack length
        design.ls = design.lsVtm * design.tm;

    elseif all(isfield(design, dimfields1))
        % The dimensions are present already, specified using the
        % radial dimensions, calculate the lengths
        design.ty = design.Ryo - design.Ryi;
        design.tc = design.Rco - design.Rci;
        design.tsb = design.Rao - design.Rtsb;
        design.g = design.Rmi - design.Rao;
        design.tm = design.Rmo - design.Rmi;
        design.tbi = design.Rbo - design.Rbi;

        design.Rco = design.Rtsb;
        design.Rci = design.Ryo;
        design.Rbi = design.Rmo;
        design.Rtsg = design.Rao - design.tsg;
        
        design.RmoVRbo = design.Rmo / design.Rbo;
        design.RmiVRmo = design.Rmi / design.Rmo;
        design.RaoVRmi = design.Rao / design.Rmi;
        design.RtsbVRao = design.Rtsb / design.Rao;
        design.RyoVRtsb = design.Ryo / design.Rtsb;
        design.RyiVRyo = design.Ryi / design.Ryo;
        design.tsgVtsb = design.tsg / design.tsb;
        
        design.thetamVthetap = design.thetam / design.thetap;
        design.thetacVthetas = design.thetac / design.thetas;
        design.thetasgVthetac = design.thetasg / design.thetac;
        design.lsVtm = design.ls / design.tm;

    elseif all(isfield(design, dimfields2))
        % The dimensions are present already, specified using lengths,
        % calculate the radial dimensions
        design.Rmo = design.Rbo - design.tbi;
        design.Rmi = design.Rmo - design.tm;
        design.Rao = design.Rmi - design.g;
        design.Rtsb = design.Rao - design.tsb;
        design.Ryo = design.Rtsb - design.tc; 
        design.Ryi = design.Ryo - design.ty;

        design.Rco = design.Rtsb;
        design.Rci = design.Ryo;
        design.Rbi = design.Rmo;
        design.Rtsg = design.Rao - design.tsg;
        
        design.RmoVRbo = design.Rmo / design.Rbo;
        design.RmiVRmo = design.Rmi / design.Rmo;
        design.RaoVRmi = design.Rao / design.Rmi;
        design.RtsbVRao = design.Rtsb / design.Rao;
        design.RyoVRtsb = design.Ryo / design.Rtsb;
        design.RyiVRyo = design.Ryi / design.Ryo;
        design.tsgVtsb = design.tsg / design.tsb;
        
        design.thetamVthetap = design.thetam / design.thetap;
        design.thetacVthetas = design.thetac / design.thetas;
        design.thetasgVthetac = design.thetasg / design.thetac;
        design.lsVtm = design.ls / design.tm;

    else
        % something's missing
        error( 'RENEWNET:pmmachines:slottedradspec', ...
               'For a slotted radial flux design with internal armature you must have the\nfields %s OR %s OR %s in the design structure.', ...
               sprintf('%s, ', ratiofields{:}), ...
               sprintf('%s, ', dimfields1{:}), ...
               sprintf('%s, ', dimfields2{:}))
    end

end