function design = completedesign_linear (design, simoptions)
% completes common design aspects to create a minimal design
%
% Syntax
%
% design = completedesign_linear (design)
% design = completedesign_linear (design, simoptions)
%
% Description
%
% completedesign_linear performs some design completion tasks common to all
% linear machines (with some exceptions, e.g. tubular machines). Most
% notably it completes the winding specification based on a minimum spec
% provided in the design structure. The winding is described using the
% following variables:
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
%  CoilLayers - the number of layers in the coil slot
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
%   Poles, Phases, Qc, CoilLayers
%   Poles, Phases, qc, CoilLayers
%   qc, Phases, NBasicWindings, CoilLayers
%
% These variables must be provided as fields in the design structure. If
% 'qc' is supplied, it must be an object of the class 'fr'. This is a class
% designed for handling fractions. See the help for the ''fr'' class for
% further information. If CoilLayers is not supplied, it defaults to 1.
%
% completedesign_linear adds various default design options common to all linear
% pm machines if they are not already present in the design structure. The
% following fields will be added to 'design' if they are not already present:
%
%  CoilLayers - default is 1
%
%  MagnetSkew - determines the amount of magnet skewwing as a ratio of a pole
%   width (i.e. it is expected to be between 0 and 1). Defaults to zero if not
%   supplied.
%
%  NStrands - number of strands making up the wire in the coils. Defaults to 1
%   if not supplied.
%
%  NStages - number of stages making up the machine. Defaults to 1 if not
%   supplied
% 
%
% Not all machine types may make use of all the default options set here.
%
%
% See also: completedesign_AM.m
%

    if nargin < 2
        simoptions = struct ();
    end
        
    % perform processing common to all machines
    design = completedesign_AM (design, simoptions);
    
end