function [T, Y, results, design, simoptions] = simulatemachine_AM(design, simoptions, simfun, finfun, odeevfun, resfun, varargin)
% performs a simulation of an electrical machine design and system
% operation using ode solvers
%
% Syntax
%
% [T, Y, results, design, simoptions] = simulatemachine_AM(design, ...
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

% Copyright Richard Crozer 2012

    % Do some parsing of opional input arguments
    Inputs.simfunargs = {};
    Inputs.finfunargs = {};
    Inputs.resfunargs = {};
    Inputs.odeargs = {};
    Inputs.Verbose = true;
    
    Inputs = parse_pv_pairs(Inputs, varargin);

    simoptions = checksimoptions_simulatemachine_linear(simoptions);

    if ~isempty(simfun)
        % Analyse the machine and gather desired data
        [design, simoptions] = feval(simfun, design, simoptions, Inputs.simfunargs{:});
    end

    if ~isempty(finfun)
        % now complete any further required modification to the design
        [design, simoptions] = feval(finfun, design, simoptions, Inputs.finfunargs{:});
    end

    % finally simulate the machine using ode solver, first setting some
    % options
    if isoctave

        if isfield(simoptions, 'reltol')
            if isfield(simoptions, 'abstol')
               simoptions.abstol = simoptions.abstol(:);
               if isscalar(simoptions.reltol) && ~isscalar(simoptions.abstol)
                   simoptions.reltol = repmat(simoptions.reltol, size(simoptions.abstol));
               end
            end
            odeoptions = odeset('RelTol', simoptions.reltol);
        else
            simoptions.reltol = 2e-2;
            if isfield(simoptions, 'abstol')
               if isscalar(simoptions.reltol) && ~isscalar(simoptions.abstol)
                   simoptions.reltol = repmat(simoptions.reltol, size(simoptions.abstol));
               end
            end
        end
        
    else
        
        if ~isfield(simoptions, 'reltol')
            simoptions.reltol = 2e-2;
        end

    end

    odeoptions = odeset('RelTol', simoptions.reltol);
    
    % choose initial step size, this is done 
    odeoptions = odeset(odeoptions, 'InitialStep', simoptions.tspan(end) / 1000);
    
    if isfield(simoptions, 'abstol')
        odeoptions = odeset(odeoptions, 'AbsTol', simoptions.abstol);
    end

    if isfield(simoptions, 'maxstep')
        odeoptions = odeset(odeoptions, 'MaxStep', simoptions.maxstep);
    end

    if isfield(simoptions, 'events')
        odeoptions = odeset(odeoptions, 'Events', simoptions.events);
    end

    % select the solver to use, by default we choose stiff solvers a
    % generally the machine inductance circuit requires this.
    if isfield(simoptions, 'odesolver')
        if ischar(simoptions.odesolver)
            odefcn = str2func(simoptions.odesolver);
        elseif isa(simoptions.odesolver, 'function_handle')
            odefcn = simoptions.odesolver;
        end
    else
        if isoctave
            odefcn = @ode2r;
        else
            odefcn = @ode15s;
        end
    end
    
    if ischar(odeevfun)
        % convert evaluation function to function handle if it's a string
        odeevfun = str2func(odeevfun);
    end
    
    if isfield(simoptions, 'splitode') 
        
        if isfield(simoptions, 'spfcn') && isa(simoptions.spfcn, 'function_handle')

            % in this case we use the odesplit function to allow longer
            % simulations to be run, only extracting pertinent values
            [results, simoptions.tspan] = odesplit(odefcn, odeevfun, simoptions.tspan, ...
                simoptions.IC, ...
                odeoptions, ...
                simoptions.spfcn, ...
                'spfcnArgs', {design, simoptions}, ...
                'OdeArgs', [{design, simoptions}, Inputs.odeargs], ...
                'Blocks', simoptions.splitode, ...
                'BlockMultiplier', 10, ...
                'ManageMemory', true, ...
                'MaxAttempts', 4, ...
                'Verbose', true);

            % append the results to the Input arguments for the resfun
            Inputs.resfunargs = [Inputs.resfunargs, {results}];

            % set T and Y to empty matrices
            T = [];
            Y = [];
        else
            error('Simoptions contains splitode field, but has missing or invalid spfcn handle');
        end
        
    else
        if Inputs.Verbose, fprintf(1, '\nBeginning ode solution\n'); end
        %tic
        %[T, Y] = odefcn(@(t, y) feval(odeevfun, t, y, design, simoptions, Inputs.odeargs{:}), simoptions.tspan, simoptions.IC, odeoptions);
        odeargs = [{design, simoptions}, Inputs.odeargs];
        [T,Y] = odefcn(odeevfun, simoptions.tspan, simoptions.IC, odeoptions, odeargs{:});
        %toc
        if Inputs.Verbose, fprintf(1, 'ode solution complete\n'); end
    end

    % Obtain any internally calculated results of interest
    [results, design] = feval(resfun, T, Y, design, simoptions, Inputs.odeargs{:}, Inputs.resfunargs{:});
    
    if isoctave
        simoptions = func2str_simulatemachine_linear(simoptions);
    end
    
end


function simoptions = checksimoptions_simulatemachine_linear(simoptions)

    if isfield(simoptions, 'simfun') && ischar(simoptions.simfun)
        simoptions.simfun = str2func(simoptions.simfun);
    end

    if isfield(simoptions, 'finfun') && ischar(simoptions.finfun)
        simoptions.finfun = str2func(simoptions.finfun);
    end

    if isfield(simoptions, 'odeevfun') && ischar(simoptions.odeevfun)
        simoptions.odeevfun = str2func(simoptions.odeevfun);
    end

    if isfield(simoptions, 'resfun') && ischar(simoptions.resfun)
        simoptions.resfun = str2func(simoptions.resfun);
    end
    
    if isfield(simoptions, 'spfcn') && ischar(simoptions.spfcn)
        simoptions.spfcn = str2func(simoptions.spfcn);
    end
    
    if isfield(simoptions, 'events')
        if iscell(simoptions.events)
            for i = 1:numel(simoptions.events)
                if ischar(simoptions.events{i})
                    simoptions.events{i} = str2func(simoptions.events{i});
                end
            end
        else
            if ischar(simoptions.events)
                simoptions.events = str2func(simoptions.events);
            end
        end
    end
end

function simoptions = func2str_simulatemachine_linear(simoptions)

    if isfield(simoptions, 'simfun') && isa(simoptions.simfun, 'function_handle')
        simoptions.simfun = func2str(simoptions.simfun);
    end

    if isfield(simoptions, 'finfun') && isa(simoptions.finfun, 'function_handle')
        simoptions.finfun = func2str(simoptions.finfun);
    end

    if isfield(simoptions, 'odeevfun') && isa(simoptions.odeevfun, 'function_handle')
        simoptions.odeevfun = func2str(simoptions.odeevfun);
    end

    if isfield(simoptions, 'resfun') && isa(simoptions.resfun, 'function_handle')
        simoptions.resfun = func2str(simoptions.resfun);
    end
    
    if isfield(simoptions, 'spfcn') && isa(simoptions.spfcn, 'function_handle')
        simoptions.spfcn = func2str(simoptions.spfcn);
    end

    if isfield(simoptions, 'events')
        if iscell(simoptions.events)
            for i = 1:numel(simoptions.events)
                if isa(simoptions.events{i}, 'function_handle')
                    simoptions.events{i} = func2str(simoptions.events{i});
                end
            end
        else
            if isa(simoptions.events, 'function_handle')
                simoptions.events = func2str(simoptions.events);
            end
        end
    end
    
end

