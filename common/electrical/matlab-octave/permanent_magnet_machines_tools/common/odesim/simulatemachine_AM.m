function [T, Y, results, design, simoptions] = simulatemachine_AM(design, simoptions, varargin)
% performs a simulation of an electrical machine design and system using
% ode solvers
%
% Syntax
%
% [T, Y, results, design, simoptions] = simulatemachine_AM (design, simoptions, 'Parameter', 'Value')
%
%
% Description
%
% simulatemachine_AM performs preprocessing, runs an ode simulation,
% optionally with memory management, and post-processes the results using
% functions supplied in 'simoptions'. 
%
% Inputs
%
% design, simoptions - structures containing all the information necessary
%   to perform the machine simultion. Their contents will depend on the
%   particular simulation and design being used. However, fields in the
%   simoptions structure are used to control how the system is evaluated.
%   Some aditional arguments are available as Parameter-value pairs which
%   will also be described below.
%
%   The following fields may be supplied:
%
%   simfun - optional function handle or string containing the function
%     which will be run to generate data prior to running the simulation.
%     simfun will be passed the design and simoptions structure, and can
%     also be supplied with additional arguments by using the
%     'ExtraSimFunArgs' parameter-value pair. The extra arguments must be
%     placed in a cell array. It must return two arguments which will
%     overwrite the design and simoptions variables.
%
%     The supplied function must have the calling syntax
%
%     [design, simoptions] = thefunction(design, simoptions, simfunarg1, simfunarg2, ...)
%
%     Where simfunarg1, simfunarg2, ... if supplied are the elements of the
%     a cell array, passed in using the Parameter-value pair
%     ExtraSimFunArgs, e.g.
%
%     simulatemachine_AM(design, simoptions, 'ExtraSimFunArgs', {1, 'another', [1,2;3,4]})
%
%   finfun - optional function handle or string containing a function which
%     will be run after simfun. finfun will also be passed the design and
%     simoptions structure, and can also be supplied with additional
%     arguments by using the 'ExtraFinFunArgs' parameter-value pair. The
%     extra arguments must be placed in a cell array. It must return two
%     arguments which will overwrite the design and simoptions variables.
%
%     The supplied function must have the calling syntax
%
%     [design, simoptions] = thefunction(design, simoptions, finfunarg1, finfunarg2, ...)
%   
%     Where finfunarg1, finfunarg2, ... if supplied are the elements of the
%     a cell array, passed in using the Parameter-value pair
%     ExtraFinFunArgs, e.g.
%
%     simulatemachine_AM(design, simoptions, 'ExtraFinFunArgs', {1, 'another', [1,2;3,4]})
%
%   odeevfun - function handle or string containing the function which will
%     be evaluated by the ode solver routines to solve the system of
%     equations. see the ode solvers (e.g. ode45, ode15s) for further
%     information on how to create a suitible function.
%
%   resfun - function handle or string containing a function which will be
%     run after the simulation has been completed by the ode solver. resfun
%     must take the T and Y matrices, as generated by the ode solver, and the
%     design and simoptions arguments in that order. resfun can also be
%     supplied with additional arguments by using the 'ExtraResFunArgs'
%     parameter-value pair. The extra arguments must be placed in a cell array.
%     It must return two arguments, one of which is a results variable
%     containing results of interest to the user, the other of which overwrites
%     the design variable.
%
%     The supplied function must have the calling syntax
%
%     [results, design] = htefunction(T, Y, design, simoptions, odearg1, odearg2, ..., resfunarg1, resfunarg1, ...);
%
%     Where odearg1, odearg2, ..., resfunarg1, resfunarg1, ... if supplied are the elements of the
%     two cell arrays, passed in using the Parameter-value pairs
%     ExtraOdeArgs and ExtraResFunArgs respectively, e.g.
%
%     simulatemachine_AM ( design, simoptions, ...
%                          'ExtraOdeArgs', {1, true}, ...
%                          'ExtraResFunArgs', {2, false} )
%
%   odesolver - function handle or string specifying the ode solver to use,
%     if not supplied, for Matlab the default is 'ode15s', and for Octave
%     'ode2r'.
%
%   splitode - (scalar integer) if this field is present in the structure
%     it indicates that the evaluation of the system of differential
%     equations should be split into manageable chunks, useful for
%     long-running simulations which use substantial memory. The value of
%     splitode is the desired initial number of chunks into which
%     evaluation will be split. If the system runs out of memory during
%     simulation, the number of blocks will be increased and simulation
%     reattempted this will be attempted at most 4 times. If splitode is
%     present, the field spfcn must also be supplied, documented below.
%
%   spfcn - (string|function handle) if splitode is provided this field
%     must also be present which should contain a string or function
%     handle. This function will be called at each break in the
%     integration and must have the following syntax:
%
%     results = spfcn (flag, results, sol, design, simoptions)
%   
%     For further information on creating a split point function, see the
%     help for 'odesplit.m'.
%
% Additional arguments are provided via Parameter-Value pairs, most of
% which are related to the contents of the simoptions fileds and are
% already described previously (such as the options to pass additional
% arguments to the simulation functions). These Parameter-Value pairs are:
%
%   'ExtraSimFunArgs' - cell array of a additional arguemts to pass to
%     simfun
%
%   'ExtraFinFunArgs' - cell array of a additional arguemts to pass to
%     funfun
%
%   'ExtraResFunArgs' - cell array of a additional arguemts to pass to
%     resfun
%
%   'ExtraOdeArgs' - cell array of a additional arguemts to pass to
%     odeevfun
%
% In addition, the following parameter-value pairs may be supplied:
%
%   'Verbose' - true or false flag determining whether to print output
%     describing the progress of the simulation. Default is true.
%
% Output
%
% T - output time vector as produced by ode solver functions, e.g. ode45
%
% Y - output solution vector as produced by ode solver functions, e.g.
%   ode45
%
% results - the results as produced by the supplied function in resfun
%
% design - the design structure which may have been modified by the
%   supplied functions
%
% simoptions - the simoptions structure which may have been modified by the
%   supplied functions
%

% Copyright Richard Crozer 2012-2016

    % Do some parsing of optional input arguments
    Inputs.ExtraSimFunArgs = {};
    Inputs.ExtraFinFunArgs = {};
    Inputs.ExtraResFunArgs = {};
    Inputs.ExtraOdeArgs = {};
    Inputs.odeevfun = true;
    Inputs.Verbose = true;
    
    Inputs = parse_pv_pairs(Inputs, varargin);
    
    % get the simululation pre-processing/data gathering function
    simfun = [];
    if isfield(simoptions, 'simfun') 
        if ischar(simoptions.simfun)
            simfun = str2func(simoptions.simfun);
        else
            simfun = simoptions.simfun;
        end
    end
    
    if ~isempty(simfun)
        % run the data gathering function for the design
        [design, simoptions] = feval(simfun, design, simoptions, Inputs.ExtraSimFunArgs{:});
    end
    
    finfun = [];
    if isfield(simoptions, 'finfun')
        if ischar(simoptions.finfun)
            finfun = str2func(simoptions.finfun);
        else
            finfun = simoptions.finfun;
        end
    end

    if ~isempty(finfun)
        % now complete any further required modification or post-processing
        % required before running the ode simulation
        [design, simoptions] = feval(finfun, design, simoptions, Inputs.ExtraFinFunArgs{:});
    end

    % if solution components info is provided construct the initial
    % conditions and tolerances etc from them
    if isfield (simoptions.ODESim, 'SolutionComponents')
        simoptions = assemble_ode_components (simoptions);
    end
    
    odeargs = [{design, simoptions}, Inputs.ExtraOdeArgs];
    
% ---- No modifications to simoptions below this point will be propogated to the ODE function

    % construct the various functions for the ode solvers. This involves
    % constructing anonymous functions to pass in the extra ode solver
    % arguments as appropriate
    [odeevfun, resfun, spfcn, eventfcns, outputfcn] = checkinputs_simulatemachine_AM(simoptions, odeargs);
    
    % finally simulate the machine using ode solver, first setting some
    % options
    if ~isfield(simoptions, 'reltol')
        simoptions.reltol = 2e-2;
    end

    odeoptions = odeset('RelTol', simoptions.reltol);
    
    % TODO: why? 
    % choose initial step size, this is done 
%     odeoptions = odeset(odeoptions, 'InitialStep', simoptions.tspan(end) / 1000);
    
    if isfield (simoptions.ODESim, 'AbsTol')
        odeoptions = odeset(odeoptions, 'AbsTol', simoptions.ODESim.AbsTol);
    end

    if isfield(simoptions, 'maxstep')
        odeoptions = odeset(odeoptions, 'MaxStep', simoptions.maxstep);
    elseif isfield (simoptions.ODESim, 'MaxStep')
        odeoptions = odeset(odeoptions, 'MaxStep', simoptions.ODESim.MaxStep);
    end

    if isfield(simoptions, 'events')
        odeoptions = odeset(odeoptions, 'Events', eventfcns);
    elseif isfield (simoptions.ODESim, 'Events')
        odeoptions = odeset(odeoptions, 'Events', eventfcns);
    end
    
    if isfield(simoptions.ODESim, 'OutputFcn')
        odeoptions = odeset(odeoptions, 'OutputFcn', outputfcn);
    end
    
    if isfield(simoptions.ODESim, 'Vectorized')
        odeoptions = odeset(odeoptions, 'Vectorized', simoptions.ODESim.Vectorized);
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
            odefcn = @ode5r; %s @oders; %@ode23s; %@ode2r;
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
            [results, simoptions.tspan] = odesplit ( odefcn, odeevfun, simoptions.tspan, ...
                simoptions.ODESim.InitialConditions, ...
                odeoptions, ...
                spfcn, ...
                'spfcnArgs', {design, simoptions}, ...
                'OdeArgs', {}, ...
                'Blocks', simoptions.splitode, ...
                'BlockMultiplier', 10, ...
                'ManageMemory', true, ...
                'MaxAttempts', 4, ...
                'Verbose', true );

            % append the results to the Input arguments for the resfun
            Inputs.ExtraResFunArgs = [Inputs.ExtraResFunArgs, {results}];

            % set T and Y to empty matrices
            T = [];
            Y = [];
        else
            error('Simoptions contains splitode field, but has missing or invalid spfcn handle');
        end
        
    else
        if Inputs.Verbose, fprintf(1, '\nBeginning ode solution\n'); end
        %tic
        %[T, Y] = odefcn(@(t, y) feval(odeevfun, t, y, design, simoptions, Inputs.odeargs{:}), simoptions.tspan, simoptions.ODESim.InitialConditions, odeoptions);
        [T,Y] = odefcn(odeevfun, simoptions.tspan, simoptions.ODESim.InitialConditions, odeoptions);
        %toc
        if Inputs.Verbose, fprintf(1, 'ode solution complete\n'); end
    end

    % Obtain any internally calculated results of interest
    [results, design] = feval(resfun, T, Y, design, simoptions, Inputs.ExtraOdeArgs{:}, Inputs.ExtraResFunArgs{:});
    
%     if isoctave
%         simoptions = func2str_simulatemachine_linear(simoptions);
%     end
    
end


function [odeevfun, resfun, spfcn, eventfcns, outputfcn] = checkinputs_simulatemachine_AM(simoptions, odeargs)

    odeevfun = [];
    if isfield(simoptions, 'odeevfun') 
        if ischar(simoptions.odeevfun)
            odeevfun = str2func(simoptions.odeevfun);
            odeevfun = @(t,y) odeevfun (t, y, odeargs{:});
        else
            odeevfun = simoptions.odeevfun;
        end
    end

    if isfield(simoptions, 'resfun') 
        if ischar(simoptions.resfun)
            resfun = str2func (simoptions.resfun);
        else
            resfun = simoptions.resfun;
        end
    end
    
    outputfcn = [];
    if isfield(simoptions.ODESim, 'OutputFcn') 
        if ischar(simoptions.ODESim.OutputFcn)
            outputfcn = str2func(simoptions.ODESim.OutputFcn);
            outputfcn = @(t,y,flag) outputfcn (t,y,flag, odeargs{:});
        end
    end
    
    spfcn = [];
    if isfield(simoptions, 'spfcn') 
        if ischar(simoptions.spfcn)
            spfcn = str2func(simoptions.spfcn);
            spfcn = @(flag, results, sol) spfcn (flag, results, sol, odeargs{:});
        end
    end
    
    eventfcns = {};
    if isfield(simoptions, 'events')
        if iscell(simoptions.events)
            eventfcns = cell (size (simoptions.events));
            for i = 1:numel(simoptions.events)
                if ischar(simoptions.events{i})
                    eventfcns{i} = str2func(simoptions.events{i});
                    eventfcns{i} = @(t,y) eventfcns{i}(t,y,odeargs{:});
                else
                    eventfcns{i} = simoptions.events{i};
                end
            end
        else
            if ischar(simoptions.events)
                eventfcns = str2func(simoptions.events);
                eventfcns = @(t,y) eventfcns(t,y,odeargs{:});
            else
                eventfcns = simoptions.events;
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

function simoptions = assemble_ode_components (simoptions)

    compnames = fieldnames (simoptions.ODESim.SolutionComponents);

    simoptions.ODESim.InitialConditions = [];
    
    simoptions.ODESim.AbsTol = [];

    for ind = 1:numel (compnames)

        simoptions.ODESim.SolutionComponents.(compnames{ind}).SolutionIndices = ...
            (numel(simoptions.ODESim.InitialConditions) + 1) : ...
                numel(simoptions.ODESim.InitialConditions)+numel(simoptions.ODESim.SolutionComponents.(compnames{ind}).InitialConditions);

        simoptions.ODESim.InitialConditions = [ simoptions.ODESim.InitialConditions, ...
                simoptions.ODESim.SolutionComponents.(compnames{ind}).InitialConditions(:)' ];
            
        if isfield (simoptions.ODESim.SolutionComponents.(compnames{ind}), 'AbsTol')
            abstol = simoptions.ODESim.SolutionComponents.(compnames{ind}).AbsTol;
        else
            abstol = nan (size(simoptions.ODESim.SolutionComponents.(compnames{ind}).InitialConditions));
        end
        
        simoptions.ODESim.AbsTol = [ simoptions.ODESim.AbsTol, ...
                                     abstol(:)' ];

    end
    
    if any (isnan(simoptions.ODESim.AbsTol))
        simoptions.ODESim = rmfield (simoptions.ODESim, 'AbsTol');
        warning ('RENEWNET:simulatemachine_AM:badabstol', ...
                 ['AbsTol not supplied for all solution components. ALL AbTol ', ...
                  'specifications have therefore been removed and will not be applied to ', ...
                  'the ode solution.'])
    end
    
    simoptions.ODESim = setfieldifabsent (simoptions.ODESim, 'OutputFcn', 'odesimoutputfcns_AM');

end

