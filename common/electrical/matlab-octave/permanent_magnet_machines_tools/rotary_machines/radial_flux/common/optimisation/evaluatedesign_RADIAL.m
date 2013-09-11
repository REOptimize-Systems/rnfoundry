function [design, simoptions, T, Y, results] = evaluatedesign_RADIAL(design, simoptions)
% simulates and evaluates the design of a radial flux permanent magnet
% machine according to the supplied simulation parameters
%
% Syntax
%
% [design, simoptions, T, Y, results] = evaluatedesign_RADIAL(design, simoptions)
%
% Input
%
% design - a structure containing the parameters of the machine or system
%   to be evaluated. The specific fields of this structure depend on the
%   system being evaluated
%
% simoptions - a structure containing parameters related to the simulation
%   of the machine/system design to be performed. The specif fields used
%   will depend on the simulation being performed, however, simoptions must
%   contain at least the following fields:
%   
%   simfun: function handle or string containing the function which will
%     be run to generate data prior to running the simulation. simfun must
%     will be passed the design and simoptions structure, and can also be
%     supplied with additional arguments by using the 'simfunargs'
%     parameter-value pair. The extra arguments must be placed in a cell
%     array. It must return two arguments which will overwrite the design
%     and simoptions variables.
%
%   finfun: function handle or string containing a function which will be
%     run after simfun. finfun will also be passed the design and
%     simoptions structure, and can also be supplied with additional
%     arguments by using the 'finfunargs' parameter-value pair. The extra
%     arguments must be placed in a cell array. It must return two
%     arguments which will overwrite the design and simoptions variables.
%
%   odeevfun: function handle or string containing the function which will
%     be evaluated by the ode solver routines to solver the system of
%     equations. see the ode solvers (e.g. ode45, ode15s) for further
%     information.
%
%   resfun: function handle or string containing a function which will be
%     run after the simulation has been completed by the ode solver. resfun
%     must take the T and Y matrices, as generated by the ode solver, and
%     the design and simoptions arguments in that order. resfun can also be
%     supplied with additional arguments by using the 'resfunargs'
%     parameter-value pair. The extra arguments must be placed in a cell
%     array. It must return two arguments, one of which is a results
%     variable containing results of interest to the user, the other of
%     which overwrites the design variable.
%
% Output
%
% design and simoptions are returned with any modifications made by the
% performed simulations. The design structure will have the following
% fields appended:
%
%   MaxDeflection: The maximum deflection in the structure of the machine
%
%   MaxStress: The maximum stress experienced in the structure of the
%     machine.
%
% T, 
%
% Y, 
%
% results
%

% Copyright Richard Crozier 2012

    % simulate the machine
    [T, Y, results, design, simoptions] = simulatemachine_AM(design, ...
                                                             simoptions, ...
                                                             simoptions.simfun, ...
                                                             simoptions.finfun, ...
                                                             simoptions.odeevfun, ...
                                                             simoptions.resfun);
    
%     % evaluate the structure, unless we are told to skip it
%     if ~simoptions.evaloptions.SkipStructural
%         [maxzdef, maxstress, design] = evaluatestructure_RADIAL(design, simoptions);
%     else
%         maxzdef = 0; 
%         maxstress = 0;
%     end
% 
%     % copy some results into the design structure
%     design.MaxDeflection = maxzdef;
%     
%     design.MaxStress = maxstress;
    
end