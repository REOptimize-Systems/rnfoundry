function rnfoundry_setup (varargin)
% setup function for the RenewNet Foundry. Sets paths and attempts to
% compile mexfunctions for best performance of the tools
%
% Syntax
%
% rnfoundry_setup ()
% rnfoundry_setup ('Parameter', value)
%
% Input
%
% rnfoundry_setup can be called with no arguments, of for finer control,
% over the install process, it can be called with additional optional
% arguemtns supplied as Parameter-Value pairs. The avaialble options are:
%
%  'ForceMexLseiSetup' : Forces the recompilation of the mexlsei mex 
%    function even if it already on the path. Default is false.
%
%  'ForceMexLseiF2cLibRecompile' : Forces the recompilation of the f2c
%    library which must be linked to by the mexlsei mex function. Default
%    is false.
%
%  'ForceMexLseiCFileCreation' : Forces the creation of the C language file
%    dlsei from the original fortran sources of dlsei using f2c. Default is
%    false in which case a presupplied version is used.
%
%  'ForceMexSLMSetup' : Forces the recompilation of the mexslmeval mex 
%    function even if it already on the path. Default is false.
%
%  'ForceMexPPValSetup' : Forces the recompilation of the mexppval mex 
%    function even if it already on the path. Default is false.
%
%  'ForceMexmPhaseWLSetup' : Forces the recompilation of the mexmPhaseWL
%    mex function even if it already on the path. Default is false.
%
%  'PreventXFemmCheck' :  Many functions in the renewnet foundry require 
%    the 'xfemm' finite element analysis package. rnfoundry_setup can
%    download and install this package if desired. This option determines
%    whether rnfoundry_setup checks to see if xfemm is already installed
%    (by looking for xfemm functions in the path). Defautl is false, so
%    rnfoundry_setup will check to see if xfemm is installed.
%
%  'XFemmInstallPrefix' : Many functions in the renewnet foundry require 
%    the 'xfemm' finite element analysis package. rnfoundry_setup can 
%    download and install this package if desired. By defualt the package
%    will be installed in the same directory as the one containing
%    rnfoundry_setup.m, you can use this option to set this to a different
%    directory.
%
%  'XFemmDownloadSource' : Many functions in the renewnet foundry require 
%    the 'xfemm' finite element analysis package. rnfoundry_setup can
%    download and install this package if desired. To change the default
%    download location (i.e. the remote url pointing to the package on the
%    internet) you can set this option. The default is a location on
%    Sourceforge.net, and depends on your machine architecture. It's fairly
%    unlikely you'll ever want to change this option.
%

    % set up the matlab path first to get access to a load of utility
    % functions we can then use
    thisfilepath = fileparts (which ('rnfoundry_setup'));
    addpath(genpath (thisfilepath));
    
    % mexlsei related
    Inputs.ForceMexLseiSetup = false;
    Inputs.ForceMexLseiF2cLibRecompile = false;
    Inputs.ForceMexLseiCFileCreation = false;
    % slm fitting tool related
    Inputs.ForceMexSLMSetup = false;
    % mex ppval related
    Inputs.ForceMexPPValSetup = false;
    % force setting up mexmPhaseWL
    Inputs.ForceMexmPhaseWLSetup = false;
    % xfemm related
    Inputs.PreventXFemmCheck = false;
    if ispc
        Inputs.XFemmDownloadSource = 'http://downloads.sourceforge.net/project/xfemm/Release/Release%201.6/xfemm_v1_6_mingw_win64.zip';
    elseif isunix
        Inputs.XFemmDownloadSource = 'http://downloads.sourceforge.net/project/xfemm/Release/Release%201.6/xfemm_v1_6_linux64.tar.gz';
    else
        Inputs.XFemmDownloadSource = '';
    end
    Inputs.XFemmInstallPrefix = fullfile (thisfilepath, 'common');
 
    % now parse the pv pairs
    Inputs = parse_pv_pairs (Inputs, varargin);
    
    if ~isoctave
        cc = mex.getCompilerConfigurations('C++');
        
        if numel (cc) == 0
           warning ( ['The renewnet foundry code will have best performance if ' ...
                      'you have set up a C++ compiler for matlab using "mex -setup". ' ...
                      'No C++ compiler seems to have been set up on your system yet. ' ... 
                      'You may wish to set this up and re-run rnfoundry_setup.']) 
        end
    end
    
    if Inputs.ForceMexLseiSetup || (exist (['mexlsei.', mexext], 'file') ~= 3)
        mexlsei_setup ( Inputs.ForceMexLseiF2cLibRecompile, ...
                        Inputs.ForceMexLseiCFileCreation );
    end
    
    if Inputs.ForceMexSLMSetup || (exist (['mexslmeval.', mexext], 'file') ~= 3)
        mexslmeval_setup ();
    end
    
    if Inputs.ForceMexPPValSetup || (exist (['mexppval.', mexext], 'file') ~= 3)
        mexppval_setup();
    end
    
    if Inputs.ForceMexmPhaseWLSetup || (exist (['mexmPhaseWL.', mexext], 'file') ~= 3)
        mmake ('', fullfile (pm_machines_tools_rootdir (), 'common', 'winding-layout', 'MMakefile.m'));
        mmake ('tidy', fullfile (pm_machines_tools_rootdir (), 'common', 'winding-layout', 'MMakefile.m'));
    end
    
    % check for the existence of xfemm package
    if ~Inputs.PreventXFemmCheck
        
        if exist ('mexfmesher', 'file') ~= 3
            
            response = '';
            while ~(strcmpi (response, 'Y') || strcmpi (response, 'N') )
                response = input( [
                    'You do not appear to have the xfemm package for performing electromagnetic\n', ...
                    'simulations which is required for many functions in the foundry\n', ...
                    'to work. Do you want to try to download and install it? (y/n): '], 's');
            end
            
            if upper(response) == 'Y'
                
                doxfemm = true;
                if ispc
                    xfemm_prefix = 'xfemm_mingw_win64';
                    xfemmfile = fullfile (tempdir, [xfemm_prefix, '.zip']);
                    urlwrite ( Inputs.XFemmDownloadSource, xfemmfile );
                    unpackfcn = @unzip;
                elseif isunix
                    xfemm_prefix = 'xfemm_linux64';
                    xfemmfile = fullfile (tempdir, [xfemm_prefix, '.tar.gz']);
                    urlwrite ( Inputs.XFemmDownloadSource, xfemmfile );
                    unpackfcn = @untar;
                else
                    fprintf ('No xfemm compiled package is currently available for mac, skipping.\n');
                    doxfemm = false;
                end

                if doxfemm
                    % unpack the download to the appropriate location
                    unpackfcn (xfemmfile, Inputs.XFemmInstallPrefix);

                    % remove the downloaded package
                    delete (xfemmfile);

                    % add mfemm setup function location to path and run it
                    addpath (fullfile (Inputs.XFemmInstallPrefix, xfemm_prefix, 'mfemm'));
                    mfemm_setup ();

                end
            else
                fprintf ('Skipping xfemm install.\n');
            end
            
        end
    end

    
end
