function [T, Y, results, design, simoptions] = simulatemachine_linear(design, simoptions, simfun, finfun, odeevfun, resfun, varargin)
% performs a simulation of a linear machine design and system operation
% using ode solvers
%
% Syntax
%
% [T, Y, results, design, simoptions] = simulatemachine_linear(design, ...
%                   simoptions, simfun, finfun, odeevfun, resfun, 'Parameter', 'Value')
%
% Inputs
%
% design, simoptions - structures containing all the information necessary
% to perform the machine simultion. Their contents will depend on the
% particular simulation and design being used
%
% simfun - function handle or string containing the function which will be
% run to generate data prior to running the simulation. simfun must will be
% passed the design and simoptions structure, and can also be supplied with
% additional arguments by using the 'simfunargs' parameter-value pair. The
% extra arguments must be placed in a cell array. It must return two
% arguments which will overwrite the design and simoptions variables.
%
% finfun - function handle or string containing a function which will be
% run after simfun. finfun will also be passed the design and simoptions
% structure, and can also be supplied with additional arguments by using
% the 'finfunargs' parameter-value pair. The extra arguments must be placed
% in a cell array. It must return two arguments which will overwrite the
% design and simoptions variables.
%
% odeevfun - function handle or string containing the function which will
% be evaluated by the ode solver routines to solver the system of
% equations. see the ode solvers (e.g. ode45, ode15s) for further
% information.
%
% resfun - function handle or string containing a function which will be
% run after the simulation has been completed by the ode solver. resfun
% must take the T and Y matrices, as generated by the ode solver, and the
% design and simoptions arguments in that order. resfun can also be
% supplied with additional arguments by using the 'resfunargs'
% parameter-value pair. The extra arguments must be placed in a cell array.
% It must return two arguments, one of which is a results variable
% containing results of interest to the user, the other of which overwrites
% the design variable.
%

% Copyright Richard Crozer, The University of Edinburgh

    % call the more generic function simulatemachine_AM
    [T, Y, results, design, simoptions] = ...
        simulatemachine_AM(design, simoptions, simfun, finfun, odeevfun, resfun, varargin{:});

end