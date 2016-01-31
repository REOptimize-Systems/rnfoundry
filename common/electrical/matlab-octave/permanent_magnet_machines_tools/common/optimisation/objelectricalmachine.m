function ObjVal = objelectricalmachine(simoptions, Chrom, preprocfcn, evalfcn, multicoredir, separatesimfun)
% a general objective function for the evaluation of electrical machines
%
% Syntax
%
% ObjVal = objelectricalmachine(simoptions, Chrom, preprocfcn, evalfcn, multicoredir)
%
% Description
%
% objelectricalmachine evaluates a chromosome of machine designs and splits
% that evaluation between multiple computers using the multicore package.
% The evaluation is split into two stages
%
% Input
%
%   simoptions - a set of simulation options for the machine and system to
%     be evaluated. objelectricalmachine requires the following fields to
%     be present in simoptions:
%
%     evaloptions - a structure containing fields providing details of how
%       the logistics of the evalauation is to be handled. It must contain
%       the followinf fields:
%
%       masterIsWorkerSimFun - scalar field which must evaluate to true or
%         false. If true the master 

% Copyright Richard Crozer 2012, The University of Edinburgh

    if nargin < 6
        separatesimfun = true;
    end
    
    if isscalar (simoptions.evaloptions.spawnslaves)
        simoptions.evaloptions.spawnslaves = ...
            [ simoptions.evaloptions.spawnslaves, simoptions.evaloptions.spawnslaves ];
    end
    
    % common multicore settings
    simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'maxattempts', 3);
    
    % preprocess the designs before simulation
    simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'MCorePreProcDir', '');
    PPsettings.multicoreDir = fullfile (multicoredir, simoptions.evaloptions.MCorePreProcDir);
    PPsettings.nResults = 2;
    PPsettings.nrOfEvalsAtOnce = 5;
    PPsettings.masterIsWorker = true;
    parameterCell = mcoreobjfcneval ( preprocfcn, construct_pp_parametercell (simoptions, Chrom), ...
                                      PPsettings, simoptions.evaloptions.maxattempts, ...
                                      'ErrorUserFcn', @mcoreerrormail, ...
                                      'TryLocalEval', true );

    for i = 1:size (parameterCell,1)

        % Construct initial design structure
%         [design, psimoptions] = feval (preprocfcn, simoptions, Chrom(i,:));

        % store various pieces of info for index for later use
        parameterCell{i}{1}.OptimInfo.ChromInd = i;
        parameterCell{i}{1}.OptimInfo.Chrom = Chrom (i,:);
%         [~,hgid] = system ( ['cd ', getmfilepath('objelectricalmachine.m'), ' ; hg id']);
%         parameterCell{i}{1}.OptimInfo.RNFoundryMercurialID = hgid;

        parameterCell{i}{2} = rmiffield (parameterCell{i}{2}, 'filenamebase');
        
%         parameterCell{i,1} = {design, psimoptions};

    end

    fprintf (1, '\nBeginning evaluation of population at %s.\n', datestr (now));

    % Determines whether the master performs work or only coordinates
    settings.masterIsWorker    = simoptions.evaloptions.masterIsWorkerSimFun;
    % This is the number of function evaluations given to each worker
    % in a batch
    settings.nrOfEvalsAtOnce   = 1;
    % The maximum time a single evaluation should take, determines
    % the timeout for a worker
    settings.maxEvalTimeSingle = 15*60;

    % Determines whether a wait bar is displayed, 0 means no wait bar
    settings.useWaitbar = 0;
    % Post processing function info
    settings.postProcessHandle   = '';
    settings.postProcessUserData = {};
    settings.debugMode = 0;
    settings.showWarnings = 1;
    simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'allowheld', 10);
        
    if separatesimfun
        
        fprintf (1, 'Beginning evaluation of population (first function) at %s.\n', datestr (now));

        % Determines whether the master performs work or only coordinates
        settings.masterIsWorker    = simoptions.evaloptions.masterIsWorkerSimFun;
        % This is the number of function evaluations given to each worker
        % in a batch
        settings.nrOfEvalsAtOnce   = 2;
        % The maximum time a single evaluation should take, determines
        % the timeout for a worker
        settings.maxEvalTimeSingle = 30*60;
        % prevent clearing of existing multicore files so we can run multiple
        % multicore evaluations at once in the same directory
        settings.clearExistingFiles = false;
        
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'MCoreFEADir', 'FEA');

        settings.multicoreDir = fullfile (multicoredir, simoptions.evaloptions.MCoreFEADir);

        % quit any slaves in the ODE directory, as we may be some time
    %     quitallslaves ( fullfile(multicoredir, 'ODE') );

        if simoptions.evaloptions.waitforotherfea
            while numel (dir (fullfile (settings.multicoreDir, 'parameters_*'))) > 0
                pause (20);
            end
        end

        if ~ispc

            if simoptions.evaloptions.spawnslaves(1)
                % use the mcorecondormatlabslavespawn function to automatically
                % spawn matlab processes to do the work
                fprintf (1, 'spawnslaves true for FEA\n');
                % set some default spawning settings if not supplied
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'starttime', [18,0,0]);
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'endtime', [8,0,0]);
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'maxslaves', 100);
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'condorlogdirectory', ...
                                            fullfile (fileparts (which ('condorslavesubmitwrite')), 'Output'));
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'condorhost', 'local');
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'condorusername', '');
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'condorpassword', '');
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'matlicencebuffer', 10);
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'matlabhost', '');
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'matlabport', '');
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'matlabpassword', '');
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'condornotifyemail', '');
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'slavestartdir', '~/Documents/MATLAB');
                simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'matoroctslaves', 'm');
                
                % set up the mcorecondormatlabslavespawn monitor function, called
                % by the multicore master process each time it looks for new files
                % to check if new matlab slaves should be spawned or not
                settings.monitorFunction = @mcorecondormatlabslavespawn;
                settings.monitorUserData = struct ('condorhost', simoptions.evaloptions.condorhost, ...
                    'matlabhost', simoptions.evaloptions.matlabhost, ...
                    'matlabport', simoptions.evaloptions.matlabport, ...
                    'matlabpassword', simoptions.evaloptions.matlabpassword, ...
                    'username', simoptions.evaloptions.condorusername, ...
                    'password', simoptions.evaloptions.condorpassword, ...
                    'starttime', simoptions.evaloptions.starttime, ...
                    'endtime', simoptions.evaloptions.endtime, ...
                    'pausetime', 5, ... % time between Condor jobs starting
                    'startuptime', 3*60, ... % time matlab takes to start
                    'sharedir', settings.multicoreDir, ...
                    'matlicencebuffer', simoptions.evaloptions.matlicencebuffer, ...
                    'deletepausetime', 60, ...
                    'maxslaves', simoptions.evaloptions.maxslaves, ...
                    'initialwait', 10*60, ... % wait 10 mins after the first slave launch before respawning
                    'allowheld', simoptions.evaloptions.allowheld, ...
                    'condorlogdirectory', simoptions.evaloptions.condorlogdirectory, ...
                    'notifyemail', simoptions.evaloptions.condornotifyemail, ...
                    'slavestartdir', simoptions.evaloptions.slavestartdir, ...
                    'matoroct', simoptions.evaloptions.matoroctslaves );

            end

        end

        % save the intermediate values in case of errors
        save (fullfile (settings.multicoreDir, ['pre_', 'mcoresimfun_AM', '_output.mat']));

        parameterCell = mcoreobjfcneval ('mcoresimfun_AM', parameterCell, ...
                                         settings, simoptions.evaloptions.maxattempts, ...
                                         'ErrorUserFcn', @mcoreerrormail, ...
                                         'TryLocalEval', true);
    end
    
    settings.masterIsWorker = simoptions.evaloptions.masterIsWorkerEvFun;
    settings.nrOfEvalsAtOnce   = 1;
    % The maximum time a single evaluation should take, determines
    % the timeout for a worker
    settings.maxEvalTimeSingle = 1.5*60*60;
    % prevent clearing of existing multicore files so we can run multiple
    % multicore evaluations at once in the same directory
    settings.clearExistingFiles = false;

    simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'MCoreODEDir', 'ODE');
    
    settings.multicoreDir = fullfile (multicoredir, simoptions.evaloptions.MCoreODEDir);

    % save the intermediate values in case of errors
    if ischar (evalfcn)
        save (fullfile (settings.multicoreDir, ['pre_', evalfcn, '_output.mat']))
    end

    if simoptions.evaloptions.spawnslaves(2)
        % use the mcorecondormatlabslavespawn function to automatically
        % spawn matlab processes to do the work
        
        % set some default spawning settings if not supplied
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'starttime', [18,0,0]);
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'endtime', [8,0,0]);
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'maxslaves', 100);
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'condorlogdirectory', ...
                                            fullfile (fileparts (which ('condorslavesubmitwrite')), 'Output'));
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'condorhost', 'local');
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'condorusername', '');
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'condorpassword', '');
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'matlicencebuffer', 10);
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'matlabhost', '');
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'matlabport', '');
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'matlabpassword', '');
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'condornotifyemail', '');
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'slavestartdir', '~/Documents/MATLAB');
        simoptions.evaloptions = setfieldifabsent (simoptions.evaloptions, 'matoroctslaves', 'm');
        
        % set up the mcorecondormatlabslavespawn monitor function, called
        % by the multicore master process each time it looks for new files
        % to check if new matlab slaves should be spawned or not
        settings.monitorFunction = @mcorecondormatlabslavespawn;
        settings.monitorUserData = struct ('condorhost', simoptions.evaloptions.condorhost, ...
            'matlabhost', simoptions.evaloptions.matlabhost, ...
            'matlabport', simoptions.evaloptions.matlabport, ...
            'matlabpassword', simoptions.evaloptions.matlabpassword, ...
            'username', simoptions.evaloptions.condorusername, ...
            'password', simoptions.evaloptions.condorpassword, ...
            'starttime', simoptions.evaloptions.starttime, ...
            'endtime', simoptions.evaloptions.endtime, ...
            'pausetime', 5, ... % time between Condor jobs starting
            'startuptime', 3*60, ... % time matlab takes to start
            'sharedir', settings.multicoreDir, ...
            'matlicencebuffer', simoptions.evaloptions.matlicencebuffer, ...
            'deletepausetime', 60, ...
            'maxslaves', simoptions.evaloptions.maxslaves, ...
            'initialwait', 10*60, ... % wait 10 mins after the first slave launch before respawning
            'allowheld', simoptions.evaloptions.allowheld, ...
            'condorlogdirectory', simoptions.evaloptions.condorlogdirectory, ...
            'notifyemail', simoptions.evaloptions.condornotifyemail, ...
            'slavestartdir', simoptions.evaloptions.slavestartdir, ...
            'matoroct', simoptions.evaloptions.matoroctslaves );

    end
    
%     if ischar (evalfcn)
%         evalfcn = str2func (evalfcn);
%     end

    fprintf (1, 'Beginning evaluation of population (second function) at %s.\n', datestr (now));
    
    if simoptions.evaloptions.waitforotherode
        waits = 0;
        while 1
            % check for parameter files, but ignoring semaphore files
            pfiles = dir (fullfile (settings.multicoreDir, 'parameters_*'));
            seminds = [];
            for ind = 1:numel (pfiles)
                if ~isempty (strfind (pfiles(ind).name, 'semaphore'));
                    seminds = [seminds, ind];
                end
            end
            % remove semaphore file listings
            pfiles(seminds) = [];
            
            if numel(pfiles) < 1
                break;
            end
            
            % wait for a little while before checking again
            if waits <= 1
                fprintf (1, 'Waiting for other ODE to complete.\n');
            elseif waits >= 10
                waits = 0;
            end
            
            pause (20);
            
            waits = waits + 1;
            
        end
        
    end
    
    ObjVal = mcoreobjfcneval (evalfcn, parameterCell, settings, ...
                              simoptions.evaloptions.maxattempts, ...
                              'ErrorUserFcn', @condorslavesoutofmemerr, ...
                              'TryLocalEval', true);

    ObjVal = reshape (cell2mat (ObjVal),[],1);

    displayresults (Chrom, ObjVal)
    
end


function displayresults (Chrom, ObjVal)
% displays the objective values for the chromosome on the command line

    for i = 2:2:size (Chrom,1)
        fprintf (1, 'Ind %d, Score: %f\tInd %d, Score: %f\n', i-1, ObjVal(i-1), i, ObjVal(i));
    end
    
    if i < size (Chrom,1)
        i = i + 1;
        fprintf (1, 'Ind %d, Score: %f\n', i, ObjVal(i));
    end

end

function parameterCell = construct_pp_parametercell (simoptions, Chrom)

    parameterCell = cell (size (Chrom, 1), 1);
    for ind = 1:size (Chrom,1)
       
        parameterCell{ind,1} = {simoptions, Chrom(ind,:)};
        
    end

end
