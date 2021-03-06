classdef hydroBody < handle
% represents one hydrodynamically interacting body in a hydrodynamic system
%
% Syntax
%
% hb = hydroBody (filename)
%
% Description
%
% wsim.hydroBody represents one hydrodynamically interacting body in a
% hydrodynamic system. It is intended to be used in conjunction with the
% wsim.hydroSystem class which manages a collection of wsim.hydroBody
% objects and is used to perform the time domain simulation of the bodies.
%
% The body simulation data is contained in a case directory. This case
% directory should contain two subdirectories, 'hydroData' and 'geometry'.
%
% The hydroData subdirectory should contain either one .h5 file containing
% the output of the BEMIO files which process the output of various BEM
% solvers to a format understood by the hydroBody class, or, a collection
% of .mat files containing hydroData structures which can be directly
% loaded by the body. In this case, there will be one mat file for each
% body.
%
% The geometry subdirectory should contain a collection of STL files, one
% for each body. 
%
% wsim.hydroBody Methods:
%
%   hydroBody - constructor for the hydroBody class
%   adjustMassMatrix - Merges diagonal term of added mass matrix to the mass matrix
%   advanceStep - advance to the next time step, accepting the current time
%   bodyGeo - Reads an STL mesh file and calculates areas and centroids
%   checkInputs - Checks the user inputs
%   forceAddedMass - Recomputes the real added mass force time history for the
%   getVelHist - not documented
%   hydroForcePre - performs pre-processing calculations to populate hydroForce structure
%   hydroForces - hydroForces calculates the hydrodynamic forces acting on a
%   hydrostaticForces - calculates the hydrostatic forces acting on the body
%   lagrangeInterp - not documented
%   linearExcitationForces - calculates linear wave excitation forces during transient
%   linearInterp - not documented
%   listInfo - Display some information about the body at the command line
%   loadHydroData - load hydrodynamic data from file or variable
%   makeMBDynComponents - creates mbdyn components for the hydroBody
%   morrisonElementForce - not documented
%   nonlinearExcitationForces - calculates the non-linear excitation forces on the body
%   offsetXYZ - Function to move the position vertices
%   plotStl - Plots the body's mesh and normal vectors
%   radForceODEOutputfcn - OutputFcn to be called after every completed ode time step
%   radForceSSDerivatives - wsim.hydroBody/radForceSSDerivatives is a function.
%   radiationForces - calculates the wave radiation forces
%   readH5File - Reads an HDF5 file containing the hydrodynamic data for the body
%   restoreMassMatrix - Restore the mass and added-mass matrix back to the original value
%   rotateXYZ - Function to rotate a point about an arbitrary axis
%   saveHydroData - saves the body's hydrodata structure to a .mat file
%   setCaseDirectory - set the case directory for the simulation the body is part of
%   setInitDisp - Sets the initial displacement when having initial rotation
%   storeForceAddedMass - Store the modified added mass and total forces history (inputs)
%   timeDomainSimReset - resets the body in readiness for a transient simulation
%   timeDomainSimSetup - sets up the body in preparation for a transient simulation
%   viscousDamping - not documented
%   waveElevation - calculate the wave elevation at centroids of triangulated surface
%   write_paraview_vtp - Writes vtp files for visualization with ParaView
%
%
% See Also: wsim.hydroSystem
%
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2014 the National Renewable Energy Laboratory and Sandia Corporation
% Modified 2017 by The University of Edinburgh
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    properties (SetAccess = protected, GetAccess = public) % hydroData h5 or mat file related
        
        % hydroData - Hydrodynamic data from BEM or user defined.
        hydroData = struct();
        
        % name - Body name. This is obtained from the h5 or mat file.
        name = [];  
        
        % cg - Center of gravity [x; y; z] in meters. 
        %  This is obtained from the h5 or mat file.
        cg = [];
        
        % cb - Center of buoyancy [x; y; z] in meters. 
        %  For WEC bodies this is given in the h5 file.
        cb = [];

        % dof - Number of DOFs. 
        %  For WEC bodies this is given in the h5 file. IF not, default is
        %  6
        dof = []      

        % dof_gbm - Number of DOFs for GBM.
        dof_gbm = []                                                  

        % dof_start - Index of DOF starts.
        %  For WEC bodies this is given in the h5 file. IF not, default is
        %  (bodyNumber-1)*6+1
        dof_start = []                             

        % dof_end - Index of DOF ends. 
        %  For WEC bodies this is given in the h5 file. IF not, default is
        %  (bodyNumber-1)*6+6
        dof_end = []                                                  
        
    end

    properties (SetAccess = public, GetAccess = public) % input file
        
        % mass - Mass in kg or specify 'equilibrium' to have mass = displacement vol * density
        mass = [];

        % momOfInertia - Moment of inertia [Ixx Iyy Izz] in kg*m^2 for the body
        momOfInertia = [];
        
        % geometryFile - Names of geomtry stl file for this body in geometry subfolder
        geometryFile = 'NONE';
        
        % dispVol Displaced volume at equilibrium position in m^3. 
        %  If dispVol is empty, it is obtained from the h5 or mat file (the
        %  default behaviour). The value in the h5 or mat file is
        %  ignored if dispVol is not empty and the selected value is used.
        dispVol = [];
        
        % viscDrag - Structure defining the viscous (quadratic) drag
        %  Must contain either the field 'Drag', or the fields 'cd' and
        %  'characteristicArea'. 
        %
        %    Drag : if supplied, this field should contain either a full 
        %     (6x6) matrix defining the Viscous (quadratic) drag, or a
        %     vector of length 6 representing the diagonal of this matrix.
        %     These are the directly specified viscous drag coefficients.
        %
        %    cd : should contain a vector length 6 defining the Viscous
        %     (quadratic) drag coefficients which will be multiplied by the
        %     corresponding values in the 'characteristicArea' field.
        %
        %    characteristicArea : should contain a vector of length 
        %     6 defining the Characteristic areas for viscous drag.
        %
        viscDrag = struct( 'Drag',                 zeros(6), ...
                           'cd',                   [0 0 0 0 0 0], ... 
                           'characteristicArea',   [0 0 0 0 0 0] );
                                
%         % initDisp - Structure defining the initial displacement.
%         %  Should contain three fields:
%         %
%         %  initLinDisp : Initial displacement of center of gravity - used
%         %   for decay tests (format: [displacment in m], default = [0 0 0])
%         %
%         %  initAngularDispAxis : Initial displacement of centre of gravity
%         %   (axis of rotation) used for decay tests (format: [x y z],
%         %   default = [1 0 0])
%         %
%         %  initAngularDispAngle : Initial displacement of centre of gravity
%         %    (angle of rotation) - used for decay tests (format: [radians],
%         %    default = 0)
%         %
%         initDisp = struct( 'initLinDisp',          [0 0 0], ... 
%                            'initAngularDispAxis',  [0 1 0], ...
%                            'initAngularDispAngle', 0 );
                       
        % (6x6) Hydrostatic stiffness matrix which overrides BEMIO definition
        hydroStiffness   = zeros(6);
                       
        % linearDamping - Linear drag coefficient, vector length 6
        linearDamping = [0 0 0 0 0 0];
        
        % Excitation IRF from BEMIO used for User-Defined Time-Series
        userDefinedExcIRF = [] ;
        
        % viz - Structure defining visualization properties for Paraview
        %  Should contain two fields, 'color' and 'opacity'.
        %
        %  color : three element vector containing the rgb values defining
        %   the body color in Paraview
        %
        %  opacity : scalar value defining the opacity of the body in 
        %   Paraview.
        %
        viz = struct( 'color', [1, 1, 0], ...                           
                      'opacity', 1 );
                               
        % morrisonElement - structure defining morrison element input
        %  Should be a structure containing the fields 'cd', 'ca',
        %  'characteristicArea', 'VME' and 'rgME'
        %
        %  cd : vector length 3 containing the viscous (quadratic) drag
        %   coefficients
        %
        %  ca : Added mass coefficent for Morrison Element (format [Ca_x
        %   Ca_y Ca_z], default = [0 0 0])
        %
        %  characteristicArea : Characteristic area for Morrison Elements
        %   calculations (format [Area_x Area_y Area_z], default = [0 0 0])
        %
        %  VME : Characteristic volume for Morrison Element (default = 0)
        %
        %  rgME : Vector from center of gravity to point of application for
        %   Morrison Element (format [X Y Z], default = [0 0 0]).
        %
        morrisonElement = struct( 'cd',                 [0 0 0], ...
                                  'ca',                 [0 0 0], ...
                                  'characteristicArea', [0 0 0], ...
                                  'VME',                 0     , ...
                                  'rgME',               [0 0 0] );

        % bodyGeometry - Structure defining body's mesh
        %  Should contain the fields 'numFace', 'numVertex', 'vertex',
        %  'face', 'norm', 'area', 'center'. Generally this is filled by
        %  reading the geometry STL file.
        %
        %  numFace : Number of faces
        %
        %  numVertex : Number of vertices
        %
        %  vertex : List of vertices
        %
        %  face : List of faces
        %
        %  norm : List of normal vectors
        %
        %  area : List of cell areas
        %
        %  center : List of cell centers
        %
        bodyGeometry = struct( 'numFace', [], ...
                               'numVertex', [], ...
                               'vertex', [], ...
                               'face', [], ...
                               'norm', [], ...
                               'area', [], ...
                               'center', [] );

        % bodyNumber - body number in the order body was added to a wsim.hydroSystem. 
        %  Can be different from the BEM body number, this is the index of
        %  the body in the wsim.hydroSystem
        bodyNumber = [];
        
        % bodyTotal - Total number of hydro bodies in the wsim.hydroSystem
        bodyTotal = [];
        
        % totalLenDOF - Matrices length. 6 for no body-to-body interactions. 6*numBodies if body-to-body interactions.
        totalLenDOF = [];  

        % flexHydroBody - Flag for flexible body. 
        flexHydroBody = 0                                                   

        % meanDriftForce - Flag for mean drift force. 0: No; 1: from control surface; 2: from momentum conservation.
        meanDriftForce = 0
    end

    properties (SetAccess = protected, GetAccess = public) % internal
        
        % hydroForce - Structure containing hydrodynamic forces and coefficients used during simulation
        %  Will be a structure containing various fields depending on what
        %  simulation settings were chosen.
        hydroForce = struct();
        
        % hydroDataBodyNum - Body number within the hdf5 file.
        hydroDataBodyNum = [];          
        
        % massCalcMethod - Method used to obtain mass: 'user', 'fixed', 'equilibrium'
        %
        %  'user' means the user has specified the mass directly
        %
        %  'fixed' means the mass is irrelevant as the hydrobody will be
        %    clamped in place, so a default set of mass and inertia values
        %    will be used.
        %
        %  'equilibrium' means the mass is calculated 
        massCalcMethod = [];  
        
        % excitationMethod - Character vector containing the wave excitation method to be used
        %  can be one of: 'noWave', 'noWaveCIC', 'regular', 'regularCIC',
        %  'irregular', 'irregularImport', 'userDefined'
        excitationMethod;
        
        % doNonLinearFKExcitation - true/false flag indicating if FK force will be calculated
        %  Indicates whether the nonlinear Froude-Krylov wave excitation
        %  forces will be calculated
        doNonLinearFKExcitation;  
        
        % radiationMethod - character vector with a description of the radiation method
        %  Contains one of the following character vectors describing what
        %  method will be used to calculated the radiation forces:
        %
        %     'constant radiation coefficients'
        %     'state space representation'
        %     'state space representation using external solver'
        %     'convolution integral'
        %
        radiationMethod;
        
        % addedMassMethod - character vector with a description of the added mass method
        %  Contains one of the following character vectors describing what
        %  method will be used to calculate the added mass forces:
        %
        %     'extrapolate acceleration from previous steps'
        %     'iterate'
        %     'mbdyn'
        addedMassMethod;
        
%         hydroRestoringForceMethod;
        
        % freeSurfaceMethod - character vector indicating what fre surface method will be used
        %  Will be 'mean' or 'instantaneous'
        freeSurfaceMethod;
        
        % bodyToBodyInteraction - true/false flag indicating if body-to-body interaction is included
        bodyToBodyInteraction;
        
        % doMorrisonElementViscousDrag - true/false flag indicating if morrison element viscous drag is included
        doMorrisonElementViscousDrag;
        
        % doViscousDamping - true/false flag indicating if viscous damping is included
        doViscousDamping;
        
        % doLinearDamping - true/false flag indicating if linear damping is included
        doLinearDamping;
        
        % doRadiationDamping - true/false flag indicating if radiation forces are included
        doRadiationDamping = true;
        
        % doAddedMass - true/false flag indicating if added mass forces are included
        doAddedMass = true;
        
        % caseDirectory - Simulation case directory containing the hydroData and geometry subdirectories
        caseDirectory;
        
        % hydroDataFile - name of hdf5 or mat file containing the hydrodynamic data (without path)
        hydroDataFile = '';          
        
        % hydroDataFileFullPath - full path to h5 or mat file containing the hydrodynamic data for the body
        hydroDataFileFullPath = ''
        
        % disableAddedMassForce - true/false flag indicating whether to calculate added mass forces
        %   If this is true, the added mass force will be set to always
        %   return [ 0; 0; 0; 0; 0; 0 ]. It is generally intended for
        %   debugging purposes only
        disableAddedMassForce = false;
        
        % disableRadiationForce - true/false flag indicating whether to calculate radiation forces
        %   If this is true, the radiation damping force will be set to
        %   always return [ 0; 0; 0; 0; 0; 0 ]. It is generally intended
        %   for debugging purposes only
        disableRadiationForce = false;

    end

    properties (SetAccess = protected, GetAccess = protected) % internal

        waves;
        simu;

        excitationMethodNum;
        radiationMethodNum;
        addedMassMethodNum;
        hydroRestoringForceMethodNum;
        freeSurfaceMethodNum;
        diagViscDrag;
        viscDragDiagVals;
        mbdynLinearDamping;
        mbdynViscousDamping; 
        mbdynAddedMass;
        noOffDiagonalAddedMassTerms = false;

        % properties used to calculate nonFKForce at reduced sample time
        oldForce    = [];
        oldWp       = [];
        oldWpMeanFs = [];

        % nonlinear buoyancy
        oldNonLinBuoyancyF = [];
        oldNonLinBuoyancyP = [];
        
        % history of last few time steps
        timeStepHist;
            
        % accel history store (used by added mass calc transport delay)
        accelHist;
        
        stepCount;

        % wave radiation force convolution integral states
        CIdt;
        radForceVelocity;
        radForceOldTime;
        radForceOldF_FM;
        radForce_IRKB_interp;

        % wave radiation forces state-space system object
        radForceSS;
        velHist;
        
        % wave elevation
        oldElev;
        
        % For storing mean drift force which doesn't change during sim: waves.A(1,:) .* waves.A(1,:) .* body.hydroForce.fExt.md(1,:)
        meanDriftForcePreCalc;

    end

    % public pre-processing related methods (and constructor)
    methods (Access = 'public') %modify object = T; output = F

        function obj = hydroBody (filename)
            % constructor for the hydroBody class
            %
            % Syntax
            %
            % hb = hydroBody (filename)
            %
            % Input
            %
            %  filename - string containing the h5 or mat file containing
            %   the hydrodynamic data for the body, without the path, e.g.
            %   float.mat, or rm3.h5. The hydrobody searches for the file
            %   in the <case_directory>/hydroData folder. The validity of
            %   the file name is not checked until the setCaseDirectory
            %   method is called (which is usually called by a parent
            %   wism.hydroSystem object which sets the case directory for
            %   all hydroBodies in a system).
            %
            % Output
            %
            %  hb - a wsim.hydroBody object
            %
            %
            
            obj.hydroDataFile = filename;
            
        end
        
        function setCaseDirectory (obj, case_directory)
            % set the case directory for the simulation the body is part of
            %
            % Syntax
            %
            % setCaseDirectory (hb, case_directory)
            %
            % Description
            %
            % setCaseDirectory sets the path to the case directory of the
            % simulation of which the hydroBody is a part. This is intended
            % to be called by the wsim.hydroSystem to which the body is
            % added, rather than called by a user directly. The case
            % directory should contain two subdirectories, 'hydroData' and
            % 'geometry'. The hydroData directory should contain the .h5
            % file or .mat file containing the hydrodynamic data for the
            % body using a BEM solver and the BEMIO functions. The geometry
            % folder should contain any STL file describing the geometry of
            % the body.
            %
            % Input
            %
            %  hb - a wsim.hydroBody object
            %
            %  case_directory - character vector containing the full path
            %   to the case directory of the simulation.
            %
            %
            % See Also: wsim.hydroSystem
            %

            hydrofile = fullfile (case_directory, 'hydroData', obj.hydroDataFile);
            
            if exist (hydrofile, 'file') ~= 2
                if exist (case_directory, 'dir') ~= 7
                    error ('The case directory %s does not appear to exist', options.CaseDirectory);
                else
                    [filepath,name,ext] = fileparts (hydrofile);
                    error ( 'The specified hydro data (%s) file \n%s\n was not found in the directory:\n%s', ...
                            ext, ...
                            [name, ext], ...
                            filepath );
                end
            end
            
            obj.caseDirectory = case_directory;
            
            obj.hydroDataFileFullPath = hydrofile;
            
        end

        function readH5File (obj)
            % Reads an HDF5 file containing the hydrodynamic data for the body
            %
            % Syntax
            %
            % readH5File(hb)
            %
            % Description
            %
            % readH5File reads the HDF5 file containing the hydrodynamic
            % data for the body and stores it in the body properties. The
            % file location is expected to be in the case directory
            % provided on construction of the object.
            %
            % Generating the hydrodynamic data:
            %
            % The hydroBody requires frequency-domain hydrodynamic
            % coefficients (added mass, radiation damping, and wave
            % excitation). Typically, these hydrodynamic coefficients for
            % each body of the WEC device are generated using a boundary
            % element method (BEM) code (e.g., WAMIT, NEMOH or AQWA). The
            % HDF5 file must then be generated from the output of these
            % codes.
            %
            % Create HDF5 file:
            %
            % readH5File reads the hydrodynamic data in HDF5 format from
            % the (<hydrodata_file_name>.h5) file provided when the object
            % was constructed. A helper tool, BEMIO, is available to parse
            % BEM solutions (from WAMIT, NEMOH and AQWA) into the required
            % HDF5 data structure. 
            %
            % Input
            %
            %  hb - hydroBody object
            %
            %
            
            filename = obj.hydroDataFileFullPath;
            body_name = ['/body' num2str(obj.bodyNumber)];
            obj.cg = h5read(filename,[body_name '/properties/cg']);
            obj.cg = obj.cg';
            obj.cb = h5read(filename,[body_name '/properties/cb']);
            obj.cb = obj.cb';
            if isempty (obj.dispVol)
                obj.dispVol = h5read(filename,[body_name '/properties/disp_vol']);
            end
            obj.name = h5read(filename,[body_name '/properties/name']);
            try obj.name = obj.name{1}; end %#ok<TRYNC>
            obj.hydroData.simulation_parameters.scaled = h5read(filename,'/simulation_parameters/scaled');
            obj.hydroData.simulation_parameters.wave_dir = h5read(filename,'/simulation_parameters/wave_dir');
            obj.hydroData.simulation_parameters.water_depth = h5read(filename,'/simulation_parameters/water_depth');
            obj.hydroData.simulation_parameters.w = h5read(filename,'/simulation_parameters/w');
            obj.hydroData.simulation_parameters.T = h5read(filename,'/simulation_parameters/T');
            obj.hydroData.properties.name = h5read(filename,[body_name '/properties/name']);
            try obj.hydroData.properties.name = obj.hydroData.properties.name{1}; end %#ok<TRYNC>
            obj.hydroData.properties.body_number = h5read(filename,[body_name '/properties/body_number']);
            obj.hydroData.properties.cg = h5read(filename,[body_name '/properties/cg']);
            obj.hydroData.properties.cb = h5read(filename,[body_name '/properties/cb']);
            obj.hydroData.properties.disp_vol = h5read(filename,[body_name '/properties/disp_vol']);
            obj.hydroData.properties.dof       = 6;
            obj.hydroData.properties.dof_start = (obj.bodyNumber-1)*6+1;
            obj.hydroData.properties.dof_end   = (obj.bodyNumber-1)*6+6;
            try obj.hydroData.properties.dof       = h5read(filename,[name '/properties/dof']);       end
            try obj.hydroData.properties.dof_start = h5read(filename,[name '/properties/dof_start']); end
            try obj.hydroData.properties.dof_end   = h5read(filename,[name '/properties/dof_end']);   end
            obj.dof       = obj.hydroData.properties.dof;
            obj.dof_start = obj.hydroData.properties.dof_start;
            obj.dof_end   = obj.hydroData.properties.dof_end;
            obj.dof_gbm   = obj.dof-6;
            obj.hydroData.hydro_coeffs.linear_restoring_stiffness = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/linear_restoring_stiffness']);
            obj.hydroData.hydro_coeffs.excitation.re = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/excitation/re']);
            obj.hydroData.hydro_coeffs.excitation.im = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/excitation/im']);
            obj.hydroData.hydro_coeffs.excitation.mag = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/excitation/mag']);
            obj.hydroData.hydro_coeffs.excitation.phase = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/excitation/phase']);
            try obj.hydroData.hydro_coeffs.excitation.impulse_response_fun.f = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/excitation/impulse_response_fun/f']); end %#ok<TRYNC>
            try obj.hydroData.hydro_coeffs.excitation.impulse_response_fun.t = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/excitation/impulse_response_fun/t']); end %#ok<TRYNC>
            obj.hydroData.hydro_coeffs.added_mass.all = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/added_mass/all']);
            obj.hydroData.hydro_coeffs.added_mass.inf_freq = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/added_mass/inf_freq']);
            obj.hydroData.hydro_coeffs.radiation_damping.all = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/radiation_damping/all']);
            try obj.hydroData.hydro_coeffs.radiation_damping.impulse_response_fun.K = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/radiation_damping/impulse_response_fun/K']); end %#ok<TRYNC>
            try obj.hydroData.hydro_coeffs.radiation_damping.impulse_response_fun.t = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/radiation_damping/impulse_response_fun/t']); end %#ok<TRYNC>
            try obj.hydroData.hydro_coeffs.radiation_damping.state_space.it = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/radiation_damping/state_space/it']); end %#ok<TRYNC>
            try obj.hydroData.hydro_coeffs.radiation_damping.state_space.A.all = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/radiation_damping/state_space/A/all']); end %#ok<TRYNC>
            try obj.hydroData.hydro_coeffs.radiation_damping.state_space.B.all = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/radiation_damping/state_space/B/all']); end %#ok<TRYNC>
            try obj.hydroData.hydro_coeffs.radiation_damping.state_space.C.all = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/radiation_damping/state_space/C/all']); end %#ok<TRYNC>
            try obj.hydroData.hydro_coeffs.radiation_damping.state_space.D.all = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/radiation_damping/state_space/D/all']); end %#ok<TRYNC>
            
            try tmp = wsim.bemio.h5load(filename, [body_name '/properties/mass']);
                obj.hydroData.gbm.mass      = tmp(obj.dof_start+6:obj.dof_end,obj.dof_start+6:obj.dof_end); clear tmp; end;
            try tmp = wsim.bemio.h5load(filename, [body_name '/properties/stiffness']);
                obj.hydroData.gbm.stiffness = tmp(obj.dof_start+6:obj.dof_end,obj.dof_start+6:obj.dof_end); clear tmp; end;
            try tmp = wsim.bemio.h5load(filename, [body_name '/properties/damping']);
                obj.hydroData.gbm.damping   = tmp(obj.dof_start+6:obj.dof_end,obj.dof_start+6:obj.dof_end); clear tmp;end;
            try obj.hydroData.hydro_coeffs.mean_drift_control_surface = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/mean_drift/control_surface/val']); end
            try obj.hydroData.hydro_coeffs.mean_drift_momentum_conservation = wsim.bemio.h5load(filename, [body_name '/hydro_coeffs/mean_drift/momentum_conservation/val']); end
            
            if obj.meanDriftForce == 0
                obj.hydroData.hydro_coeffs.mean_drift = 0.*obj.hydroData.hydro_coeffs.excitation.re;
            elseif obj.meanDriftForce == 1
                obj.hydroData.hydro_coeffs.mean_drift = obj.hydroData.hydro_coeffs.mean_drift_control_surface;
            elseif obj.meanDriftForce == 2
                obj.hydroData.hydro_coeffs.mean_drift = obj.hydroData.hydro_coeffs.mean_drift_momentum_conservation;
            else
                error('Wrong flag for mean drift force.')
            end
        end

        function loadHydroData (obj, hydroData)
            % load hydrodynamic data from file or variable
            %
            % Syntax
            %
            % loadHydroData (obj)
            % loadHydroData (obj, filename)
            % loadHydroData (obj, hydroData)
            %
            % Description
            %
            % Loads hydrodynamic data from a .mat file, .h5 file or
            % directly from a matlab structure.
            %
            % Input
            %
            %  hg - wsim.hydroBody object
            %
            %  filename - character vector containing the full path of the
            %   file from which to load the hydrodynamic data. Can be
            %   either a .h5 file or a .mat file. If a .mat file it must
            %   contain all the fields expected to be in the hydroBody
            %   hydroData property. This file can also be created using the
            %   wsim.hydroBody.saveHydroData method.
            %
            %  hydroData - structure containing the data which is loaded
            %   directly into the hydrBody's hydroData property
            %
            %
            % See Also: wsim.hydroBody.readH5File,
            %           wsim.hydroBody.saveHydroData
            %
            
            if nargin < 2
                hydroData = obj.hydroDataFileFullPath;
            end
            
            if ischar (hydroData)
                
                if exist (hydroData, 'file') == 0
                    error ('file: "%s" not found.', hydroData);
                end
                
                [~,basename,ext] = fileparts (hydroData);
                
                obj.hydroDataFileFullPath = hydroData;
                obj.hydroDataFile = [basename, ext];
                    
                switch ext
                    
                    case '.mat'
                        
                        hd = load (obj.hydroDataFileFullPath);
                        
                        obj.loadHydroData (hd);
                        
                    case '.h5'
                        
                        readH5File (obj);
                        
                    otherwise
                        
                        error ('Unsupported file extension "%s". Must be .mat or .h5', ext);
                        
                end
                    
            elseif isstruct (hydroData)
                
                obj.hydroData = hydroData;
                obj.cg        = hydroData.properties.cg';
                obj.cb        = hydroData.properties.cb';
                if isempty (obj.dispVol)
                    obj.dispVol   = hydroData.properties.disp_vol;
                end
                obj.name      = hydroData.properties.name;
                
                if isfield (obj.hydroData.properties, 'dof')
                    
                    obj.dof       = obj.hydroData.properties.dof;
                    obj.dof_start = obj.hydroData.properties.dof_start;
                    obj.dof_end   = obj.hydroData.properties.dof_end;
                    obj.dof_gbm   = obj.dof-6;
                    
                else
                    
                    obj.dof       = 6;
                    obj.dof_start = 1;
                    obj.dof_end   = 6;
                    obj.dof_gbm   = obj.dof-6;

                end
                
            else
                
                error ('hydroData must be a character vector or a structure.');
                
            end
            
            
            
            
        end
        
        function saveHydroData (obj, filename, varargin)
            % saves the body's hydrodata structure to a .mat file
            %
            % Syntax
            %
            % saveHydroData (hb, filename)
            % saveHydroData (..., 'Parameter', Value)
            %
            % Description
            %
            % saveHydroData saves the body's hydroData structure to a .mat
            % file for later use. This avoids having to read the .h5 file.
            % By default saveHydroData saves the file in the hydroData
            % subdirectory of the case directory. The 'Directory' option
            % may be used to change this behaviour.
            %
            % Input
            %
            %  hb - wsim.hydroBody object
            %
            %  filename - name withput path of the .mat file in which to
            %   save the hydrobody hydroData structure contents.
            %
            % Addtional arguments may be supplied as parameter-value pairs.
            % The available options are:
            %
            %  'Directory' - optional alternative directory in which to
            %    save the .mat file instead of the hydroData subdirectory
            %    of the simulation case directory.
            %
            % See Also: wsim.hydroBody.loadHydroData
            %

            options.FileName = [ obj.name, '.mat' ];
            options.Directory = fullfile (obj.caseDirectory, 'hydroData');
            
            options = parse_pv_pairs (options, varargin);
            
            assert (ischar (options.Directory), ...
                'Directory must be a character vector' );
            
            if ~exist (options.Directory, 'dir')
                mkdir (options.Directory);
            end
            
            if isempty (fieldnames(obj.hydroData))
                warning ('hydroData property is empty, so it will not be saved to file');
            else
                tmphdata = obj.hydroData;
                save (fullfile (options.Directory, filename), '-struct', 'tmphdata');
            end
            
        end

        function hydroForcePre(obj)
            % performs pre-processing calculations to populate hydroForce structure
            %
            % Syntax
            %
            % hydroForcePre (hb)
            %
            % Description
            %
            % hydroForcePre performs various pre-processing calulations in
            % prepration for a simulation. It populates the hydroForce
            % property of the hydroBody as a structure with the linear
            % hydrodynamic restoring coefficient, viscous drag, and linear
            % damping matrices, and also sets the wave excitation force
            % calculation method from the specified wave type.
            %
            % Input
            %
            %  hb - wsim.hydroBody object
            %

                  
            rho = obj.simu.rho;
            g = obj.simu.g;
            gbmDOF = obj.dof_gbm;
            
            if (gbmDOF > 0)
                
                obj.linearDamping = [obj.linearDamping zeros(1,obj.dof-length(obj.linearDamping))];
                tmp0 = obj.viscDrag.Drag;
                tmp1 = size(obj.viscDrag.Drag);
                obj.viscDrag.Drag = zeros (obj.dof);
                obj.viscDrag.Drag(1:tmp1(1),1:tmp1(2)) = tmp0;
                obj.viscDrag.cd   = [obj.viscDrag.cd   zeros(1,obj.dof-length(obj.viscDrag.cd  ))];
                obj.viscDrag.characteristicArea = [obj.viscDrag.characteristicArea zeros(1,obj.dof-length(obj.viscDrag.characteristicArea))];
                
                clear tmp0 tmp1
                
            end
            
            if obj.meanDriftForce == 0
                obj.hydroData.hydro_coeffs.mean_drift = 0 .* obj.hydroData.hydro_coeffs.excitation.re;
            elseif obj.meanDriftForce == 1
                obj.hydroData.hydro_coeffs.mean_drift = obj.hydroData.hydro_coeffs.mean_drift_control_surface;
            elseif obj.meanDriftForce == 2
                obj.hydroData.hydro_coeffs.mean_drift = obj.hydroData.hydro_coeffs.mean_drift_momentum_conservation;
            else
                error('meanDriftForce must be an integer value: 0, 1 or 2')
            end
            
            obj.setMassMatrix(rho, obj.simu.nlHydro)
            
            % check if obj.hydroStiffness is defined directly
            if ischar (obj.hydroStiffness)
                if strcmpi (obj.hydroStiffness, 'zero')
                    obj.hydroForce.linearHydroRestCoef = zeros (6);
                else
                    error ('hydroStiffness is an unrecognised character vector');
                end
            else
                if any(any(obj.hydroStiffness)) == 1
                    obj.hydroForce.linearHydroRestCoef = obj.hydroStiffness;
                else
                    k = obj.hydroData.hydro_coeffs.linear_restoring_stiffness;
                    obj.hydroForce.linearHydroRestCoef = k .* rho .* g;
                end
            end
            
            % check if obj.viscDrag.Drag is defined directly
            if  isfield (obj.viscDrag, 'Drag') && (any(any(obj.viscDrag.Drag)) == 1)
                if isvector (obj.viscDrag.Drag)
                    obj.viscDrag.Drag = diag (obj.viscDrag.Drag);
                end
                obj.hydroForce.visDrag = obj.viscDrag.Drag;                
            else
                obj.hydroForce.visDrag = diag (0.5 * rho .* obj.viscDrag.cd .* obj.viscDrag.characteristicArea);
            end
            
            if all (obj.hydroForce.visDrag(:) == 0)
                obj.doViscousDamping = false;
            end
            
            if isdiag (obj.hydroForce.visDrag)
                obj.diagViscDrag = true;
                obj.viscDragDiagVals = diag (obj.hydroForce.visDrag);
            else
                obj.diagViscDrag = false;
            end
            
            if all (obj.linearDamping == 0)
                obj.doLinearDamping = false;
            end
            
            obj.hydroForce.linearDamping = diag (obj.linearDamping);
            
            % initialize userDefinedFe for non user-defined cases
            obj.hydroForce.userDefinedFe = zeros (length (obj.waves.waveAmpTime(:,2)), obj.dof);
            
            switch obj.waves.type
                case {'noWave'}
                    obj.noExcitation ()
                    obj.constAddedMassAndDamping ();
                    obj.excitationMethodNum = 0;
                    
                case {'noWaveCIC'}
                    obj.noExcitation ()
                    obj.irfInfAddedMassAndDamping ();
                    obj.excitationMethodNum = 0;
                    
                case {'regular'}
                    obj.regExcitation ();
                    if obj.simu.ssCalc == 0
                        obj.constAddedMassAndDamping ();
                    else
                        obj.irfInfAddedMassAndDamping ();
                    end
                    obj.excitationMethodNum = 1;
                    
                    % precalculate the constant mean drift force
                    obj.meanDriftForcePreCalc = (obj.waves.A(1,:) .* obj.waves.A(1,:) .* obj.hydroForce.fExt.md(1,:))';
            
                case {'regularCIC'}
                    obj.regExcitation ();
                    obj.irfInfAddedMassAndDamping ();
                    obj.excitationMethodNum = 1;
                    
                    % precalculate the constant mean drift force
                    obj.meanDriftForcePreCalc = (obj.waves.A(1,:) .* obj.waves.A(1,:) .* obj.hydroForce.fExt.md(1,:))';
                    
                case {'irregular', 'spectrumImport'}
                    obj.irrExcitation ();
                    obj.irfInfAddedMassAndDamping ();
                    obj.excitationMethodNum = 2;
                    
                case {'etaImport'}
                    obj.userDefinedExcitation (obj.waves.waveAmpTime);
                    obj.irfInfAddedMassAndDamping ();
                    obj.excitationMethodNum = 3;
                    
                case {'sinForce'}
                    obj.sinForceExcitation ();
                    obj.zeroAddedMassAndDamping ();
                    obj.excitationMethodNum = 4;
                    
                case {'sinForceCIC'}
                    obj.sinForceExcitation ();
                    obj.irfInfAddedMassAndDamping ();
                    obj.excitationMethodNum = 4;
                    
            end

            % store the description of the wave type for information later
            obj.excitationMethod = obj.waves.type;
            
            if (gbmDOF > 0)
                
                obj.hydroForce.gbm.stiffness=obj.hydroData.gbm.stiffness;
                obj.hydroForce.gbm.damping=obj.hydroData.gbm.damping;
                obj.hydroForce.gbm.mass_ff=obj.hydroForce.fAddedMass(7:obj.dof,obj.dof_start+6:obj.dof_end)+obj.hydroData.gbm.mass;   % need scaling for hydro part
                obj.hydroForce.fAddedMass(7:obj.dof,obj.dof_start+6:obj.dof_end) = 0;
                obj.hydroForce.gbm.mass_ff_inv=inv(obj.hydroForce.gbm.mass_ff);
                
                % state-space formulation for solving the GBM
                obj.hydroForce.gbm.state_space.A = [zeros(gbmDOF,gbmDOF),...
                    eye(gbmDOF,gbmDOF);...  % move to ... hydroForce sector with scaling .
                    -inv(obj.hydroForce.gbm.mass_ff)*obj.hydroForce.gbm.stiffness,-inv(obj.hydroForce.gbm.mass_ff)*obj.hydroForce.gbm.damping];             % or create a new fun for all flex parameters
                obj.hydroForce.gbm.state_space.B = eye(2*gbmDOF,2*gbmDOF);
                obj.hydroForce.gbm.state_space.C = eye(2*gbmDOF,2*gbmDOF);
                obj.hydroForce.gbm.state_space.D = zeros(2*gbmDOF,2*gbmDOF);
                obj.flexHydroBody = 1;
                
            end
            
            

        end

        function adjustMassMatrix(obj)
            % Merges diagonal terms of added mass matrix to the mass matrix
            %
            % Syntax
            %
            % adjustMassMatrix (hb)
            %
            % Description
            %
            % adjustMassMatrix performs the following tasks in preparation
            % for a simulation:
            %
            % * Stores the original mass and added-mass properties
            % * Adds diagonal added-mass inertia to moment of inertia
            % * Adds the maximum diagonal translational added-mass to body
            % mass
            %
            % Input
            %
            %  hb - wsim.hydroBody object
            %

            iBod = obj.bodyNumber;
            obj.hydroForce.storage.mass = obj.mass;
            obj.hydroForce.storage.momOfInertia = obj.momOfInertia;
            obj.hydroForce.storage.fAddedMass = obj.hydroForce.fAddedMass;
            
            if obj.simu.b2b == true
                tmp_added_mass = obj.hydroForce.fAddedMass( 1:3, (1+(iBod-1)*6):(1+(iBod-1)*6)+2 );
            else
                tmp_added_mass = obj.hydroForce.fAddedMass( 1:3,1:3 );
            end
            
            tmp_added_mass(1,1) = 0;
            tmp_added_mass(2,2) = 0;
            tmp_added_mass(3,3) = 0;
            
            obj.noOffDiagonalAddedMassTerms = ~(any (any (tmp_added_mass)));
                
            if obj.disableAddedMassForce
                
                obj.hydroForce.fAddedMass = zeros (size (obj.hydroForce.fAddedMass));
                
            elseif obj.mbdynAddedMass
                
                if obj.simu.b2b == true

                    % clear the main diagonal terms in the mass matrix as
                    % mbdyn will handle these terms (but not off-diagonal
                    % terms)
                    obj.hydroForce.fAddedMass(1,1+(iBod-1)*6) = 0;
                    obj.hydroForce.fAddedMass(2,2+(iBod-1)*6) = 0;
                    obj.hydroForce.fAddedMass(3,3+(iBod-1)*6) = 0;
                    
                    % clear the whole added inertia matrix as mbdyn will
                    % handle all of this
                    obj.hydroForce.fAddedMass(4:6,(4+(iBod-1)*6):(4+(iBod-1)*6)+2) = 0;
                    
                else
 
                    % clear the main diagonal terms in the mass matrix as
                    % mbdyn will handle these terms (but not off-diagonal
                    % terms)
                    obj.hydroForce.fAddedMass(1,1) = 0;
                    obj.hydroForce.fAddedMass(2,2) = 0;
                    obj.hydroForce.fAddedMass(3,3) = 0;
                    
                    % clear the whole added inertia matrix as mbdyn will
                    % handle all of this
                    obj.hydroForce.fAddedMass(4:6,4:6) = 0;
                    
                end
                
            else
                
                if obj.simu.b2b == true
                    
                    tmp.fadm = diag (obj.hydroForce.fAddedMass(:,1+(iBod-1)*6:6+(iBod-1)*6));
                    tmp.adjmass = sum(tmp.fadm(1:3)) * obj.simu.adjMassWeightFun;
                    obj.mass = obj.mass + tmp.adjmass;
                    obj.momOfInertia = obj.momOfInertia+tmp.fadm(4:6)';
                    obj.hydroForce.fAddedMass(1,1+(iBod-1)*6) = obj.hydroForce.fAddedMass(1,1+(iBod-1)*6) - tmp.adjmass;
                    obj.hydroForce.fAddedMass(2,2+(iBod-1)*6) = obj.hydroForce.fAddedMass(2,2+(iBod-1)*6) - tmp.adjmass;
                    obj.hydroForce.fAddedMass(3,3+(iBod-1)*6) = obj.hydroForce.fAddedMass(3,3+(iBod-1)*6) - tmp.adjmass;
                    obj.hydroForce.fAddedMass(4,4+(iBod-1)*6) = 0;
                    obj.hydroForce.fAddedMass(5,5+(iBod-1)*6) = 0;
                    obj.hydroForce.fAddedMass(6,6+(iBod-1)*6) = 0;
                    
                else
                    
                    tmp.fadm = diag(obj.hydroForce.fAddedMass);
                    tmp.adjmass = sum (tmp.fadm(1:3)) * obj.simu.adjMassWeightFun;
                    obj.mass = obj.mass + tmp.adjmass;
                    obj.momOfInertia = obj.momOfInertia + tmp.fadm(4:6)';
                    obj.hydroForce.fAddedMass(1,1) = obj.hydroForce.fAddedMass(1,1) - tmp.adjmass;
                    obj.hydroForce.fAddedMass(2,2) = obj.hydroForce.fAddedMass(2,2) - tmp.adjmass;
                    obj.hydroForce.fAddedMass(3,3) = obj.hydroForce.fAddedMass(3,3) - tmp.adjmass;
                    obj.hydroForce.fAddedMass(4,4) = 0;
                    obj.hydroForce.fAddedMass(5,5) = 0;
                    obj.hydroForce.fAddedMass(6,6) = 0;
                    
                end
                
            end
            
        end

        function restoreMassMatrix(obj)
            % Restore the mass and added-mass matrix back to the original value
            tmp = struct;
            tmp.mass = obj.mass;
            tmp.momOfInertia = obj.momOfInertia;
            tmp.hydroForce_fAddedMass = obj.hydroForce.fAddedMass;
            obj.mass = obj.hydroForce.storage.mass;
            obj.momOfInertia = obj.hydroForce.storage.momOfInertia;
            obj.hydroForce.fAddedMass = obj.hydroForce.storage.fAddedMass;
            obj.hydroForce.storage = tmp; clear tmp
        end

        function storeForceAddedMass(obj,am_mod,ft_mod)
            % Store the modified added mass and total forces history (inputs)
            obj.hydroForce.storage.output_forceAddedMass = am_mod;
            obj.hydroForce.storage.output_forceTotal = ft_mod;
        end

%         function setInitDisp(obj, x_rot, ax_rot, ang_rot, addLinDisp)
%             % Sets the initial displacement when having initial rotation
%             %
%             % Syntax
%             %
%             % setInitDisp (hb, x_rot, ax_rot, ang_rot, addLinDisp)
%             %
%             % Description
%             %
%             % Sets the initial displacement of the body when having initial
%             % rotation.
%             %
%             % Input
%             %
%             %  hb - wsim.hydroBody object
%             %
%             %  x_rot - rotation point
%             %
%             %  ax_rot - axis about which to rotate (must be a normal vector)
%             %
%             %  ang_rot - rotation angle in radians
%             %
%             %  addLinDisp - initial linear displacement (in addition to the
%             %   displacement caused by rotation)
%             %
% 
%             relCoord = obj.cg - x_rot;
% 
%             rotatedRelCoord = hydroBody.rotateXYZ(relCoord, ax_rot, ang_rot);
% 
%             newCoord = rotatedRelCoord + x_rot;
% 
%             linDisp = newCoord - obj.cg;
% 
%             obj.initDisp.initLinDisp = linDisp + addLinDisp;
% 
%             obj.initDisp.initAngularDispAxis = ax_rot;
% 
%             obj.initDisp.initAngularDispAngle = ang_rot;
% 
%         end

        function listInfo(obj)
            % Display some information about the body at the command line
            
            fprintf('\n\t***** Body Number %G, Name: %s *****\n',obj.hydroData.properties.body_number,obj.hydroData.properties.name)
            fprintf('\tBody CG                          (m) = [%G,%G,%G]\n',obj.hydroData.properties.cg)
            fprintf('\tBody Mass                       (kg) = %G \n',obj.mass);
            fprintf('\tBody Diagonal MOI              (kgm2)= [%G,%G,%G]\n',obj.momOfInertia)
        end

        function bodyGeo(obj,fname)
            % Reads an STL mesh file and calculates areas and centroids
            %
            % Syntax
            %
            % bodyGeo (hb, fname)
            %
            % Description
            %
            % bodyGeo
            %
            % Input
            %
            %  hb - wsim.hydroBody object
            %
            %  fname - (optional) full path to the STL file to be loaded.
            %   If not supplied, the file specified in the body's
            %   geometryFile property (and expected to be in the 'geometry'
            %   folder of the simulation case directory) will be used.
            %
            
            if nargin < 2
                if isempty (obj.geometryFile) || strcmp (obj.geometryFile, 'NONE')
                    error ('No geometry file is specified in the ''geometryFile'' property of the body, and the full path to an STL file has also not be specified');
                end
                fname = fullfile (obj.caseDirectory, 'geometry', obj.geometryFile);
            end
            
            assert (exist (fname, 'file') == 2, 'The STl file:\n%s\n does not appear to exist', fname);
            
%             try
%                 [obj.bodyGeometry.vertex, obj.bodyGeometry.face, obj.bodyGeometry.norm] = import_stl_fast (fname,1,1);
%             catch
%                 [obj.bodyGeometry.vertex, obj.bodyGeometry.face, obj.bodyGeometry.norm] = import_stl_fast (fname,1,2);
%             end
            
            [obj.bodyGeometry.vertex, obj.bodyGeometry.face, obj.bodyGeometry.norm] = stl.read (fname);
            
            obj.bodyGeometry.numFace = length (obj.bodyGeometry.face);
            obj.bodyGeometry.numVertex = length (obj.bodyGeometry.vertex);
            obj.checkStl ();
            obj.triArea ();
            obj.triCenter ();
            
        end

        function plotStl(obj)
            % Plots the body's mesh and normal vectors
            c = obj.bodyGeometry.center;
            tri = obj.bodyGeometry.face;
            p = obj.bodyGeometry.vertex;
            n = obj.bodyGeometry.norm;
            figure()
            hold on
            trimesh (tri,p(:,1),p(:,2),p(:,3))
            quiver3 (c(:,1),c(:,2),c(:,3),n(:,1),n(:,2),n(:,3))
            hold off
        end
        
        function [hax, hfig, hplot] = plotAddedMass (obj, varargin)
            
            options.Axes = [];
            
            options = parse_pv_pairs (options, varargin);
            
            if isempty (options.Axes)
            
                hfig = []; % formatBEMOutputPlot will create the plot
                Title = 'Normalized Added Mass: $$\bar{A}_{i,j}(\omega) = {\frac{A_{i,j}(\omega)}{\rho}}$$';
                
            else
                hfig = get (options.Axes, 'Parent');                
            end
            
            Subtitles = {'Surge','Heave','Pitch'};
            XLables = {'$$\omega (rad/s)$$','$$\omega (rad/s)$$','$$\omega (rad/s)$$'};
            YLables = {'$$\bar{A}_{1,1}(\omega)$$','$$\bar{A}_{3,3}(\omega)$$','$$\bar{A}_{5,5}(\omega)$$'};
            
            X = obj.hydroData.simulation_parameters.w;

            rowstart = 0;
            
            if obj.simu.b2b
                
                colstart = 6* (obj.bodyTotal - 1);
                
                Y(1,1,:) = squeeze(obj.hydroData.hydro_coeffs.added_mass.all(rowstart+1,colstart+1,:));
                Y(2,1,:) = squeeze(obj.hydroData.hydro_coeffs.added_mass.all(rowstart+3,colstart+3,:));
                Y(3,1,:) = squeeze(obj.hydroData.hydro_coeffs.added_mass.all(rowstart+5,colstart+5,:));

            else
                
                colstart = 0;
                Y(1,1,:) = squeeze(obj.hydroData.hydro_coeffs.added_mass.all(rowstart+1,colstart+1,:));
                Y(2,1,:) = squeeze(obj.hydroData.hydro_coeffs.added_mass.all(rowstart+3,colstart+3,:));
                Y(3,1,:) = squeeze(obj.hydroData.hydro_coeffs.added_mass.all(rowstart+5,colstart+5,:));              
                
            end
            
            data_names{1,1} = obj.name;
            data_names{2,1} = obj.name;
            data_names{3,1} = obj.name;
            
            Notes = {'Notes:',...
                ['$$\bullet$$ $$\bar{A}_{i,j}(\omega)$$ should tend towards a constant, ',...
                '$$A_{\infty}$$, within the specified $$\omega$$ range.'],...
                ['$$\bullet$$ Only $$\bar{A}_{i,j}(\omega)$$ for the surge, heave, and ',...
                'pitch DOFs are plotted here. If another DOF is significant to the system, ',...
                'that $$\bar{A}_{i,j}(\omega)$$ should also be plotted and verified before ',...
                'proceeding.']};
            
            obj.formatBEMOutputPlot (Title,Subtitles,XLables,YLables,X,Y,data_names,Notes, ...
                 'Figure', hfig, 'Axes', options.Axes );
            
        end
        
        function [hax, hfig, hplot] = plotRadiationDamping (obj, varargin)
            
            options.Axes = [];
            
            options = parse_pv_pairs (options, varargin);
            
            if isempty (options.Axes)
            
                hfig = []; % formatBEMOutputPlot will create the plot
                Title = 'Normalized Radiation Damping: $$\bar{B}_{i,j}(\omega) = {\frac{B_{i,j}(\omega)}{\rho\omega}}$$';
                
            else
                hfig = get (options.Axes, 'Parent');                
            end
            
            Subtitles = {'Surge','Heave','Pitch'};
            XLables = {'$$\omega (rad/s)$$','$$\omega (rad/s)$$','$$\omega (rad/s)$$'};
            YLables = {'$$\bar{B}_{1,1}(\omega)$$','$$\bar{B}_{3,3}(\omega)$$','$$\bar{B}_{5,5}(\omega)$$'};
            
            X = obj.hydroData.simulation_parameters.w;

            rowstart = 0;
            
            if obj.simu.b2b
                
                colstart = 6* (obj.bodyTotal - 1);
                
                Y(1,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.all(rowstart+1,colstart+1,:));
                Y(2,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.all(rowstart+3,colstart+3,:));
                Y(3,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.all(rowstart+5,colstart+5,:));

            else
                
                colstart = 0;
                Y(1,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.all(rowstart+1,colstart+1,:));
                Y(2,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.all(rowstart+3,colstart+3,:));
                Y(3,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.all(rowstart+5,colstart+5,:));              
                
            end
            
            data_names{1,1} = obj.name;
            data_names{2,1} = obj.name;
            data_names{3,1} = obj.name;
            
            Notes = {'Notes:',...
                    ['$$\bullet$$ $$\bar{B}_{i,j}(\omega)$$ should tend towards zero within ',...
                    'the specified $$\omega$$ range.'],...
                    ['$$\bullet$$ Only $$\bar{B}_{i,j}(\omega)$$ for the surge, heave, and ',...
                    'pitch DOFs are plotted here. If another DOF is significant to the system ',...
                    'that $$\bar{B}_{i,j}(\omega)$$ should also be plotted and verified before ',...
                    'proceeding.']};
            
            obj.formatBEMOutputPlot (Title,Subtitles,XLables,YLables,X,Y,data_names,Notes, ...
                 'Figure', hfig, 'Axes', options.Axes );
            
        end

        function [hax, hfig, hplot] = plotExcitationForceMagnitude (obj, varargin)
            
            options.Axes = [];
            
            options = parse_pv_pairs (options, varargin);
            
            if isempty (options.Axes)
            
                hfig = []; % formatBEMOutputPlot will create the plot
                Title = ['Normalized Excitation Force Magnitude: ',...
                         '$$\bar{X_i}(\omega,\beta) = {\frac{X_i(\omega,\beta)}{{\rho}g}}$$'];
                
            else
                hfig = get (options.Axes, 'Parent');                
            end
            
            B = 1;
            
            beta = obj.hydroData.simulation_parameters.wave_dir(B);
            
            Subtitles = {'Surge','Heave','Pitch'};
            XLables = {'$$\omega (rad/s)$$','$$\omega (rad/s)$$','$$\omega (rad/s)$$'};
            YLables = {['$$\bar{X_1}(\omega,\beta$$',' = ',num2str(beta),'$$^{\circ}$$)'],...
                       ['$$\bar{X_3}(\omega,\beta$$',' = ',num2str(beta),'$$^{\circ}$$)'],...
                       ['$$\bar{X_5}(\omega,\beta$$',' = ',num2str(beta),'$$^{\circ}$$)'] };
            
            X = obj.hydroData.simulation_parameters.w;

            rowstart = 0;
            Y(1,1,:) = squeeze(obj.hydroData.hydro_coeffs.excitation.mag(rowstart+1,B,:));
            Y(2,1,:) = squeeze(obj.hydroData.hydro_coeffs.excitation.mag(rowstart+3,B,:));
            Y(3,1,:) = squeeze(obj.hydroData.hydro_coeffs.excitation.mag(rowstart+5,B,:));              
            
            data_names{1,1} = obj.name;
            data_names{2,1} = obj.name;
            data_names{3,1} = obj.name;
            
            Notes = {''};
            
            obj.formatBEMOutputPlot (Title,Subtitles,XLables,YLables,X,Y,data_names,Notes, ...
                 'Figure', hfig, 'Axes', options.Axes );
            
        end
        
        function [hax, hfig, hplot] = plotExcitationForcePhase (obj, varargin)
            
            options.Axes = [];
            
            options = parse_pv_pairs (options, varargin);
            
            if isempty (options.Axes)
            
                hfig = []; % formatBEMOutputPlot will create the plot
                Title = 'Excitation Force Phase: $$\phi_i(\omega,\beta)$$';
                
            else
                hfig = get (options.Axes, 'Parent');                
            end
            
            B = 1;
            
            beta = obj.hydroData.simulation_parameters.wave_dir(B);
            
            Subtitles = {'Surge','Heave','Pitch'};
            XLables = {'$$\omega (rad/s)$$','$$\omega (rad/s)$$','$$\omega (rad/s)$$'};
            YLables = {['$$\phi_1(\omega,\beta$$',' = ',num2str(beta),'$$^{\circ})$$'],...
                       ['$$\phi_3(\omega,\beta$$',' = ',num2str(beta),'$$^{\circ}$$)'],...
                       ['$$\phi_5(\omega,\beta$$',' = ',num2str(beta),'$$^{\circ}$$)'] };
            
            X = obj.hydroData.simulation_parameters.w;

            rowstart = 0;
            Y(1,1,:) = squeeze(obj.hydroData.hydro_coeffs.excitation.phase(rowstart+1,B,:));
            Y(2,1,:) = squeeze(obj.hydroData.hydro_coeffs.excitation.phase(rowstart+3,B,:));
            Y(3,1,:) = squeeze(obj.hydroData.hydro_coeffs.excitation.phase(rowstart+5,B,:));              
            
            data_names{1,1} = obj.name;
            data_names{2,1} = obj.name;
            data_names{3,1} = obj.name;
            
            Notes = {''};
            
            obj.formatBEMOutputPlot (Title,Subtitles,XLables,YLables,X,Y,data_names,Notes, ...
                 'Figure', hfig, 'Axes', options.Axes );
            
        end
        
        
        function [hax, hfig, hplot] = plotRadiationIRF (obj, varargin)
            
            options.Axes = [];
            
            options = parse_pv_pairs (options, varargin);
            
            if isempty (options.Axes)
            
                hfig = []; % formatBEMOutputPlot will create the plot
                Title = ['Normalized Radiation Impulse Response Functions: ',...
                         '$$\bar{K}_{i,j}(t) = {\frac{2}{\pi}}\int_0^{\infty}{\frac{B_{i,j}(\omega)}{\rho}}\cos({\omega}t)d\omega$$'];
                
            else
                hfig = get (options.Axes, 'Parent');                
            end
            
            Subtitles = {'Surge','Heave','Pitch'};
            XLables = {'$$t (s)$$','$$t (s)$$','$$t (s)$$'};
            YLables = {'$$\bar{K}_{1,1}(t)$$','$$\bar{K}_{3,3}(t)$$','$$\bar{K}_{3,3}(t)$$'};
            
            X = obj.hydroData.hydro_coeffs.radiation_damping.impulse_response_fun.t;

            rowstart = 0;
            
            if obj.simu.b2b
                
                colstart = 6* (obj.bodyTotal - 1);
                
                Y(1,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.impulse_response_fun.K(rowstart+1,colstart+1,:));
                Y(2,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.impulse_response_fun.K(rowstart+3,colstart+3,:));
                Y(3,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.impulse_response_fun.K(rowstart+5,colstart+5,:));

            else
                
                colstart = 0;
                Y(1,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.impulse_response_fun.K(rowstart+1,colstart+1,:));
                Y(2,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.impulse_response_fun.K(rowstart+3,colstart+3,:));
                Y(3,1,:) = squeeze(obj.hydroData.hydro_coeffs.radiation_damping.impulse_response_fun.K(rowstart+5,colstart+5,:));              
                
            end
            
            data_names{1,1} = obj.name;
            data_names{2,1} = obj.name;
            data_names{3,1} = obj.name;
            
            Notes = {'Notes:',...
                     ['$$\bullet$$ The IRF should tend towards zero within the specified timeframe. ',...
                      'If it does not, attempt to correct this by adjusting the $$\omega$$ and ',...
                      '$$t$$ range and/or step size used in the IRF calculation.'],...
                     ['$$\bullet$$ Only the IRFs for the surge, heave, and pitch DOFs are plotted ',...
                      'here. If another DOF is significant to the system, that IRF should also ',...
                      'be plotted and verified before proceeding.']};
            
            obj.formatBEMOutputPlot (Title,Subtitles,XLables,YLables,X,Y,data_names,Notes, ...
                 'Figure', hfig, 'Axes', options.Axes );
            
        end
        
        
        function [hax, hfig, hplot] = plotExcitationIRF (obj, varargin)
            
            options.Axes = [];
            
            options = parse_pv_pairs (options, varargin);
            
            if isempty (options.Axes)
            
                hfig = []; % formatBEMOutputPlot will create the plot
                Title = ['Normalized Excitation Impulse Response Functions:   ',...
                         '$$\bar{K}_i(t) = {\frac{1}{2\pi}}\int_{-\infty}^{\infty}{\frac{X_i(\omega,\beta)e^{i{\omega}t}}{{\rho}g}}d\omega$$'];
                
            else
                hfig = get (options.Axes, 'Parent');                
            end
            
            B = 1;
            
            beta = obj.hydroData.simulation_parameters.wave_dir(B);

            Subtitles = {'Surge','Heave','Pitch'};
            XLables = {'$$t (s)$$','$$t (s)$$','$$t (s)$$'};
            YLables = {['$$\bar{K}_1(t,\beta$$',' = ',num2str(beta),'$$^{\circ}$$)'],...
                       ['$$\bar{K}_3(t,\beta$$',' = ',num2str(beta),'$$^{\circ}$$)'],...
                       ['$$\bar{K}_5(t,\beta$$',' = ',num2str(beta),'$$^{\circ}$$)']};

            X = obj.hydroData.hydro_coeffs.excitation.impulse_response_fun.t;

            rowstart = 0;
            Y(1,1,:) = squeeze(obj.hydroData.hydro_coeffs.excitation.impulse_response_fun.f(rowstart+1,B,:));
            Y(2,1,:) = squeeze(obj.hydroData.hydro_coeffs.excitation.impulse_response_fun.f(rowstart+3,B,:));
            Y(3,1,:) = squeeze(obj.hydroData.hydro_coeffs.excitation.impulse_response_fun.f(rowstart+5,B,:));              
            
            data_names{1,1} = obj.name;
            data_names{2,1} = obj.name;
            data_names{3,1} = obj.name;
            
            Notes = {'Notes:',...
                     ['$$\bullet$$ The IRF should tend towards zero within the specified timeframe. ',...
                      'If it does not, attempt to correct this by adjusting the $$\omega$$ and ',...
                      '$$t$$ range and/or step size used in the IRF calculation.'],...
                     ['$$\bullet$$ Only the IRFs for the first wave heading, surge, heave, and ',...
                      'pitch DOFs are plotted here. If another wave heading or DOF is significant ',...
                      'to the system, that IRF should also be plotted and verified before proceeding.']};
            
            obj.formatBEMOutputPlot (Title,Subtitles,XLables,YLables,X,Y,data_names,Notes, ...
                 'Figure', hfig, 'Axes', options.Axes );
            
        end
        

        function checkInputs(obj)
            % Checks the user inputs
            
            % hydro data file
            if exist (fullfile (obj.hydroDataFileFullPath),'file') == 0 % && obj.nhBody==0
                
                error ( 'The hydro data file %s does not exist', ...
                        obj.hydroDataFileFullPath );
                
            end
            
            % geometry file
            if ~isempty (obj.geometryFile)
                geomfile = fullfile (obj.caseDirectory, 'geometry', obj.geometryFile);

                if exist (geomfile, 'file') == 0

                    error ( 'Could not locate and open geometry file:\n%s', ...
                            geomfile )

                end
            end
            
        end
        
        function [node, body, elements] = makeMBDynComponents (obj)
            % creates mbdyn components for the hydroBody
            %
            % Syntax
            %
            % [node, body] = makeMBDynComponents (obj)
            %
            % Description
            %
            % makeMBDynComponents creates a node and body element for use
            % in an MBDyn multibody dynamics simulation. Requires the MBDyn
            % toolbox.
            %
            % Input
            %
            %  hg - wsim.hydroBody object
            %
            % Output
            %
            %  node - mbdyn.pre.structuralNode6dof object represetning an
            %    inertial node located at the centre of gravity of the body.
            %
            %  body - mbdyn.pre.body object attached to the node and with
            %    the appropriate mass and inertial proerties for the
            %    hydroBody.
            %
            %
            
            gref = mbdyn.pre.globalref;
            
%             obj.initDisp.initLinDisp = linDisp + addLinDisp;
% 
%             obj.initDisp.initAngularDispAxis = ax_rot;
% 
%             obj.initDisp.initAngularDispAngle = ang_rot;
            
            ref_hydroBody = mbdyn.pre.reference ( obj.cg, [], [], [], 'Parent', gref);

            node = mbdyn.pre.structuralNode6dof ('dynamic', 'AbsolutePosition', ref_hydroBody.pos);

            if ~isempty (obj.geometryFile)
                stl_file = fullfile (obj.caseDirectory, 'geometry', obj.geometryFile);
            else
                stl_file = '';
            end
            
            body = mbdyn.pre.body ( obj.mass,  ...
                                    [0;0;0], ...
                                    diag (obj.momOfInertia), ...
                                    node, ...
                                    'STLFile', stl_file );
                      
            elements = {};
            
            if obj.doAddedMass && obj.mbdynAddedMass
            
                iBod = obj.bodyNumber;
                
                if obj.simu.b2b == true
                    tmp_added_mass = obj.hydroForce.storage.fAddedMass( 1:3, (1+(iBod-1)*6):(1+(iBod-1)*6)+2 );
                else
                    tmp_added_mass = obj.hydroForce.storage.fAddedMass( 1:3,1:3 );
                end
                
                if obj.simu.b2b == true
                    added_inertia_mat = obj.hydroForce.storage.fAddedMass( 4:6, (4+(iBod-1)*6):(4+(iBod-1)*6)+2 );
                else
                    added_inertia_mat = obj.hydroForce.storage.fAddedMass( 4:6,4:6 );
                end
                
                added_mass = mbdyn.pre.addedMassAndInertia ( [ tmp_added_mass(1,1); 
                                                               tmp_added_mass(2,2); 
                                                               tmp_added_mass(3,3) ], ...
                                                              [0;0;0], ...
                                                              added_inertia_mat, ...
                                                              node );
                                                              
                elements = [elements, {added_mass}];
                
            end
            
            if obj.doLinearDamping && obj.mbdynLinearDamping
                
                linear_damping_law = mbdyn.pre.linearViscousGenericConstituativeLaw (obj.hydroForce.linearDamping);

                j_viscous_body = mbdyn.pre.viscousBody (node, linear_damping_law, 'null');
                
                elements = [elements, {j_viscous_body}];

            end
            
            if obj.doViscousDamping && obj.mbdynViscousDamping
                
                if obj.diagViscDrag == false
                    error ('You cannot use MBDyn to perform viscous drag with a non-diaagonal viscous drag matrix');
                end
                
                quad_viscous_damping_law = mbdyn.pre.symbolicViscousConstituativeLaw ({'vel1', 'vel2', 'vel3', 'avel1', 'avel2', 'avel3'}, ...
                                                                                      { sprintf('%s * tanh(1000*vel1) * vel1^2', mbdyn.pre.base.formatNumber (obj.viscDragDiagVals(1))), ...
                                                                                        sprintf('%s * tanh(1000*vel2) * vel2^2', mbdyn.pre.base.formatNumber (obj.viscDragDiagVals(2))), ...
                                                                                        sprintf('%s * tanh(1000*vel3) * vel3^2', mbdyn.pre.base.formatNumber (obj.viscDragDiagVals(3))), ...
                                                                                        sprintf('%s * tanh(1000*avel1) * avel1^2', mbdyn.pre.base.formatNumber (obj.viscDragDiagVals(4))), ...
                                                                                        sprintf('%s * tanh(1000*avel2) * avel2^2', mbdyn.pre.base.formatNumber (obj.viscDragDiagVals(5))), ...
                                                                                        sprintf('%s * tanh(1000*avel3) * avel3^2', mbdyn.pre.base.formatNumber (obj.viscDragDiagVals(6))) });

                j_quad_viscous_body = mbdyn.pre.viscousBody (node, quad_viscous_damping_law, 'null');
                
                elements = [elements, {j_quad_viscous_body}];
                
            end
            
        end
        
    end

    % non-public pre-processing methods
    methods (Access = 'protected') %modify object = T; output = F
        
        
        function triArea (obj)
            % Function to calculate the area of a triangle
            points = obj.bodyGeometry.vertex;
            faces = obj.bodyGeometry.face;
            v1 = points(faces(:,3),:) - points(faces(:,1),:);
            v2 = points(faces(:,2),:) - points(faces(:,1),:);
            av_tmp =  1/2 .* (cross(v1,v2));
            area_mag = sqrt (av_tmp(:,1).^2 + av_tmp(:,2).^2 + av_tmp(:,3).^2);
            obj.bodyGeometry.area = area_mag;
        end

        function checkStl (obj)
            % Function to check STL file
            tnorm = obj.bodyGeometry.norm;
            %av = zeros(length(area_mag),3);
            %av(:,1) = area_mag.*tnorm(:,1);
            %av(:,2) = area_mag.*tnorm(:,2);
            %av(:,3) = area_mag.*tnorm(:,3);
            %if sum(sum(sign(av_tmp))) ~= sum(sum(sign(av)))
            %    warning(['The order of triangle vertices in ' obj.geometryFile ' do not follow the right hand rule. ' ...
            %        'This will causes visualization errors in the SimMechanics Explorer'])
            %end
            norm_mag = sqrt (tnorm(:,1).^2 + tnorm(:,2).^2 + tnorm(:,3).^2);
            check = sum(norm_mag)/length(norm_mag);
            if check > 1.01 || check < 0.99
                error(['length of normal vectors in ' obj.geometryFile ' is not equal to one.'])
            end
        end

        function triCenter (obj)
            % Calculate the center coordinate of the body geometries'
            % triangles
            %
            points = obj.bodyGeometry.vertex;
            faces = obj.bodyGeometry.face;
            c = zeros (length (faces), 3);
            c(:,1) = ( points(faces(:,1),1) + points(faces(:,2),1) + points(faces(:,3),1) ) ./ 3;
            c(:,2) = ( points(faces(:,1),2) + points(faces(:,2),2) + points(faces(:,3),2) ) ./ 3;
            c(:,3) = ( points(faces(:,1),3) + points(faces(:,2),3) + points(faces(:,3),3) ) ./ 3;
            obj.bodyGeometry.center = c;
        end

        function noExcitation (obj)
            % Set excitation force for no excitation case
            nDOF = obj.dof;
            obj.hydroForce.fExt.re=zeros(1,nDOF);
            obj.hydroForce.fExt.im=zeros(1,nDOF);
        end

        function regExcitation (obj)
            % Regular wave excitation force
            % Used by hydroForcePre
            nDOF = obj.dof;
            re = obj.hydroData.hydro_coeffs.excitation.re(:,:,:) .* obj.simu.rho .* obj.simu.g;
            im = obj.hydroData.hydro_coeffs.excitation.im(:,:,:) .* obj.simu.rho .* obj.simu.g;
            md = obj.hydroData.hydro_coeffs.mean_drift(:,:,:)    .* obj.simu.rho .* obj.simu.g;
            obj.hydroForce.fExt.re = zeros(1,nDOF);
            obj.hydroForce.fExt.im = zeros(1,nDOF);
            obj.hydroForce.fExt.md=zeros(1,nDOF);

            for ii=1:nDOF
                
                if length(obj.hydroData.simulation_parameters.wave_dir) > 1
                    
                    [X,Y] = meshgrid ( obj.hydroData.simulation_parameters.w, ...
                                       obj.hydroData.simulation_parameters.wave_dir);
                    
                    obj.hydroForce.fExt.re(ii) = interp2 (X, Y, squeeze(re(ii,:,:)), obj.waves.w, obj.waves.waveDir);
                    obj.hydroForce.fExt.im(ii) = interp2 (X, Y, squeeze(im(ii,:,:)), obj.waves.w, obj.waves.waveDir);
                    obj.hydroForce.fExt.md(ii) = interp2(X, Y, squeeze(md(ii,:,:)), obj.waves.w, obj.waves.waveDir);
                elseif obj.hydroData.simulation_parameters.wave_dir == obj.waves.waveDir
                    
                    obj.hydroForce.fExt.re(ii) = interp1 (obj.hydroData.simulation_parameters.w, squeeze(re(ii,1,:)), obj.waves.w, 'spline');
                    obj.hydroForce.fExt.im(ii) = interp1 (obj.hydroData.simulation_parameters.w, squeeze(im(ii,1,:)), obj.waves.w, 'spline');
                    obj.hydroForce.fExt.md(ii) = interp1(obj.hydroData.simulation_parameters.w,squeeze(md(ii,1,:)), obj.waves.w,'spline');
                    
                end
                
            end
            
        end
        
        function sinForceExcitation (obj)
            % Excitation with a specified sinusoidal force (for testing)
            % Used by hydroForcePre

            obj.hydroForce.fExt.re = zeros(1,6);
            obj.hydroForce.fExt.im = zeros(1,6);
            
            % H is actually the magnitude of the force in this case
            obj.hydroForce.fExt.re(3) = obj.waves.H (obj.bodyNumber)/2;
            
        end

        function irrExcitation (obj)
            % Irregular wave excitation force
            % Used by hydroForcePre
            nDOF = obj.dof;
            re = obj.hydroData.hydro_coeffs.excitation.re(:,:,:) .* obj.simu.rho .* obj.simu.g;
            im = obj.hydroData.hydro_coeffs.excitation.im(:,:,:) .* obj.simu.rho .* obj.simu.g;
            md = obj.hydroData.hydro_coeffs.mean_drift(:,:,:)    .* obj.simu.rho .* obj.simu.g;

            obj.hydroForce.fExt.re = zeros (obj.waves.numFreq, nDOF);
            obj.hydroForce.fExt.im = zeros (obj.waves.numFreq, nDOF);
            obj.hydroForce.fExt.md = zeros(length(obj.waves.waveDir), obj.waves.numFreq, nDOF);

            for ii=1:nDOF
                if length (obj.hydroData.simulation_parameters.wave_dir) > 1
                    
                    [X,Y] = meshgrid (obj.hydroData.simulation_parameters.w, ...
                                      obj.hydroData.simulation_parameters.wave_dir);
                                  
                    obj.hydroForce.fExt.re(:,ii) = interp2 (X, Y, squeeze(re(ii,:,:)), obj.waves.w, obj.waves.waveDir);
                    
                    obj.hydroForce.fExt.im(:,ii) = interp2 (X, Y, squeeze(im(ii,:,:)), obj.waves.w, obj.waves.waveDir);

                    obj.hydroForce.fExt.md(:,:,ii) = interp2(X, Y, squeeze(md(ii,:,:)), obj.waves.w, obj.waves.waveDir);

                elseif obj.hydroData.simulation_parameters.wave_dir == obj.waves.waveDir
                    
                    obj.hydroForce.fExt.re(:,ii) = interp1 (obj.hydroData.simulation_parameters.w, squeeze(re(ii,1,:)), obj.waves.w, 'spline');
                    
                    obj.hydroForce.fExt.im(:,ii) = interp1 (obj.hydroData.simulation_parameters.w, squeeze(im(ii,1,:)), obj.waves.w, 'spline');

                    obj.hydroForce.fExt.md(:,:,ii) = interp1 (obj.hydroData.simulation_parameters.w, squeeze(md(ii,1,:)), obj.waves.w, 'spline');
                    
                end
            end
        end

        function userDefinedExcitation (obj, waveAmpTime)
            % Calculated User-Defined wave excitation force with non-causal
            % convolution Used by hydroForcePre
            nDOF = obj.dof;

            kf = obj.hydroData.hydro_coeffs.excitation.impulse_response_fun.f .* obj.simu.rho .* obj.simu.g;
            kt = obj.hydroData.hydro_coeffs.excitation.impulse_response_fun.t;
            t =  min(kt):obj.simu.dt:max(kt);
            
            for ii = 1:nDOF
                
                if length (obj.hydroData.simulation_parameters.wave_dir) > 1
                    
                    [X,Y] = meshgrid (kt, obj.hydroData.simulation_parameters.wave_dir);
                    
                    kernel = squeeze (kf(ii,:,:));
                    
                    obj.userDefinedExcIRF = interp2 (X, Y, kernel, t, obj.waves.waveDir);
                    
                elseif obj.hydroData.simulation_parameters.wave_dir == obj.waves.waveDir
                    
                    kernel = squeeze (kf(ii,1,:));
                    
                    obj.userDefinedExcIRF = interp1 (kt,kernel,min(kt):obj.simu.dt:max(kt));
                else
                    
                    error('Default wave direction different from hydro database value. Wave direction (waves.waveDir) should be specified on input file.')
                
                end
                obj.hydroForce.userDefinedFe(:,ii) = conv (waveAmpTime(:,2), obj.userDefinedExcIRF, 'same') * obj.simu.dt;
                
            end
            
            % create piecewise polynomial(s) to interpolate the user
            % defined wave excitation
            obj.hydroForce.userDefinedFeInterp = interp1 (waveAmpTime(:,1), obj.hydroForce.userDefinedFe, 'linear', 'pp');
            
            obj.hydroForce.fExt.re = zeros(1,nDOF);
            obj.hydroForce.fExt.im = zeros(1,nDOF);
            obj.hydroForce.fExt.md = zeros(1,nDOF);
        end

        function constAddedMassAndDamping (obj)
            % Set added mass and damping for a specific frequency
            % Used by hydroForcePre
            
            am = obj.hydroData.hydro_coeffs.added_mass.all .* obj.simu.rho;
            
            rd = obj.hydroData.hydro_coeffs.radiation_damping.all .* obj.simu.rho;
            
            for i = 1:length (obj.hydroData.simulation_parameters.w)
                rd(:,:,i) = rd(:,:,i) .* obj.hydroData.simulation_parameters.w(i);
            end
            % Change matrix size: B2B [6x6n], noB2B [6x6]
            if obj.bodyToBodyInteraction == true
                LDOF = 6*obj.bodyTotal;
                obj.hydroForce.fAddedMass = zeros(6,LDOF);
                obj.hydroForce.fDamping = zeros(6,LDOF);
                obj.hydroForce.totDOF  =zeros(6,LDOF);
                for ii=1:6
                    for jj=1:LDOF
                        obj.hydroForce.fAddedMass(ii,jj) = interp1 (obj.hydroData.simulation_parameters.w,squeeze(am(ii,jj,:)), obj.waves.w, 'spline');
                        obj.hydroForce.fDamping  (ii,jj) = interp1 (obj.hydroData.simulation_parameters.w,squeeze(rd(ii,jj,:)), obj.waves.w, 'spline');
                    end
                end
                    
            else
                nDOF = obj.dof;
                obj.hydroForce.fAddedMass = zeros(nDOF,nDOF);
                obj.hydroForce.fDamping = zeros(nDOF,nDOF);
                obj.hydroForce.totDOF  =zeros(nDOF,nDOF);

                for ii=1:nDOF
                    for jj=1:nDOF
                        jjj = obj.dof_start-1+jj;
                        obj.hydroForce.fAddedMass(ii,jj) = interp1 (obj.hydroData.simulation_parameters.w,squeeze(am(ii,jjj,:)), obj.waves.w, 'spline');
                        obj.hydroForce.fDamping  (ii,jj) = interp1 (obj.hydroData.simulation_parameters.w,squeeze(rd(ii,jjj,:)), obj.waves.w, 'spline');
                    end
                end
                    
            end
        end
        
        function zeroAddedMassAndDamping (obj)
            LDOF = 6*obj.bodyTotal;
            obj.hydroForce.fAddedMass = zeros (6, LDOF);
            obj.hydroForce.fDamping = zeros (6, LDOF);
            obj.hydroForce.totDOF  = zeros (6, LDOF);
        end

        function irfInfAddedMassAndDamping (obj)
            % Set radiation force properties using impulse response function
            % Used by hydroForcePre
            % Added mass at infinite frequency
            % Convolution integral raditation damping
            % State space formulation
            nDOF = obj.dof;
            LDOF = obj.totalLenDOF;

            % Convolution integral formulation
            if obj.bodyToBodyInteraction == true
                obj.hydroForce.fAddedMass = obj.hydroData.hydro_coeffs.added_mass.inf_freq .* obj.simu.rho;
            else
                obj.hydroForce.fAddedMass = obj.hydroData.hydro_coeffs.added_mass.inf_freq(:,obj.dof_start:obj.dof_end) .* obj.simu.rho;
            end
            
            % Radition IRF
            obj.hydroForce.fDamping=zeros(nDOF,LDOF);
            irfk = obj.hydroData.hydro_coeffs.radiation_damping.impulse_response_fun.K .* obj.simu.rho;
            irft = obj.hydroData.hydro_coeffs.radiation_damping.impulse_response_fun.t;
            %obj.hydroForce.irkb=zeros(CIkt,6,obj.totalLenDOF);
            if obj.bodyToBodyInteraction == true
                for ii=1:nDOF
                    for jj=1:LDOF
                        obj.hydroForce.irkb(:,ii,jj) = interp1 (irft,squeeze(irfk(ii,jj,:)), obj.simu.CTTime, 'spline', 0);
                    end
                end
            else
                for ii=1:nDOF
                    for jj=1:LDOF
                        jjj = obj.dof_start-1+jj;
                        obj.hydroForce.irkb(:,ii,jj) = interp1 (irft,squeeze(irfk(ii,jjj,:)), obj.simu.CTTime, 'spline', 0);
                    end
                end
            end
            % State Space Formulation
            if obj.simu.ssCalc > 0
                
                if obj.bodyToBodyInteraction == true
                    
                    for ii = 1:nDOF
                        
                        for jj = 1:LDOF
                            
                            arraySize = obj.hydroData.hydro_coeffs.radiation_damping.state_space.it(ii,jj);
                            
                            if ii == 1 && jj == 1 % Begin construction of combined state, input, and output matrices
                                
                                Af(1:arraySize,1:arraySize) = obj.hydroData.hydro_coeffs.radiation_damping.state_space.A.all(ii,jj,1:arraySize,1:arraySize);
                                
                                Bf(1:arraySize,jj)          = obj.hydroData.hydro_coeffs.radiation_damping.state_space.B.all(ii,jj,1:arraySize,1);
                                
                                Cf(ii,1:arraySize)          = obj.hydroData.hydro_coeffs.radiation_damping.state_space.C.all(ii,jj,1,1:arraySize);
                                
                            else
                                
                                Af(size(Af,1)+1:size(Af,1)+arraySize,size(Af,2)+1:size(Af,2)+arraySize) ...
                                    = obj.hydroData.hydro_coeffs.radiation_damping.state_space.A.all(ii,jj,1:arraySize,1:arraySize);
                                
                                Bf(size(Bf,1)+1:size(Bf,1)+arraySize,jj) = obj.hydroData.hydro_coeffs.radiation_damping.state_space.B.all(ii,jj,1:arraySize,1);
                                
                                Cf(ii,size(Cf,2)+1:size(Cf,2)+arraySize) = obj.hydroData.hydro_coeffs.radiation_damping.state_space.C.all(ii,jj,1,1:arraySize);
                                
                            end
                            
                        end
                        
                    end
                    
                    obj.hydroForce.ssRadf.D = zeros (nDOF,LDOF);
                    
                else
                    
                    for ii = 1:nDOF
                        
                        for jj = obj.dof_start:obj.dof_end
                            
                            jInd = jj-obj.dof_start+1;
                            
                            arraySize = obj.hydroData.hydro_coeffs.radiation_damping.state_space.it(ii,jj);
                            
                            if ii == 1 && jInd == 1 % Begin construction of combined state, input, and output matrices
                                
                                Af(1:arraySize,1:arraySize) = obj.hydroData.hydro_coeffs.radiation_damping.state_space.A.all(ii,jj,1:arraySize,1:arraySize);
                                Bf(1:arraySize,jInd)        = obj.hydroData.hydro_coeffs.radiation_damping.state_space.B.all(ii,jj,1:arraySize,1);
                                Cf(ii,1:arraySize)          = obj.hydroData.hydro_coeffs.radiation_damping.state_space.C.all(ii,jj,1,1:arraySize);
                                
                            else
                                
                                Af(size(Af,1)+1:size(Af,1)+arraySize,size(Af,2)+1:size(Af,2)+arraySize) = obj.hydroData.hydro_coeffs.radiation_damping.state_space.A.all(ii,jj,1:arraySize,1:arraySize);
                                Bf(size(Bf,1)+1:size(Bf,1)+arraySize,jInd) = obj.hydroData.hydro_coeffs.radiation_damping.state_space.B.all(ii,jj,1:arraySize,1);
                                Cf(ii,size(Cf,2)+1:size(Cf,2)+arraySize)   = obj.hydroData.hydro_coeffs.radiation_damping.state_space.C.all(ii,jj,1,1:arraySize);
                                
                            end
                            
                        end
                        
                    end
                    
                    obj.hydroForce.ssRadf.D = zeros (nDOF,nDOF);
                end
                
                obj.hydroForce.ssRadf.A = Af;
                obj.hydroForce.ssRadf.B = Bf;
                obj.hydroForce.ssRadf.C = Cf .* obj.simu.rho;

            end
        end

        function setMassMatrix (obj, rho, nlHydro)
            % Sets mass for the special cases of body at equilibrium or fixed
            % Used by hydroForcePre
            if strcmp(obj.mass, 'equilibrium')
                obj.massCalcMethod = obj.mass;
                if nlHydro == 0
                    obj.mass = obj.hydroData.properties.disp_vol * rho;
                else
                    z = obj.bodyGeometry.center(:,3) + obj.cg(3);
                    z(z>0) = 0;
                    area = obj.bodyGeometry.area;
                    av = [area area area] .* -obj.bodyGeometry.norm;
                    tmp = rho*[z z z].*-av;
                    obj.mass = sum(tmp(:,3));
                end
            elseif strcmp(obj.mass, 'fixed')
                obj.massCalcMethod = obj.mass;
                obj.mass = 999;
                obj.momOfInertia = [999 999 999];
            else
                obj.massCalcMethod = 'user';
            end
        end

    end

    % public transient simulation methods
    methods (Access = 'public')
        
        
        function timeDomainSimSetup (obj, waves, simu, bodynum)
            % sets up the body in preparation for a transient simulation
            %
            % Syntax
            %
            % timeDomainSimSetup (hb, waves, simu, bodynum)
            %
            % Desciription
            %
            % timeDomainSimSetup initialises various parmaters and settings in
            % preparation for performing a transient simulation based on
            % the ODE solver routines. 
            %
            % Input
            %
            %   hb - hydroBody object
            %
            %   waves - waveClass object with the desired wave parameters
            %     to be used in the simulation
            %
            %   simu - simulationClass Object with the desired simulation
            %     parameters to be used in the simulation
            %
            %   bodynum - the number associated with this body. Typically
            %     this is generated by a parent hydrosys object
            %
            % 
            
            assert (isa (simu, 'wsim.simSettings'), 'waves must be a wsim.simSettings object')
            assert (isa (waves, 'wsim.waveSettings'), 'waves must be a wsim.waveSettings object');
            assert (check.isScalarInteger (bodynum, false) , 'bodynum must be a scalar integer')

            % store waves and simu for later access
            obj.waves = waves;
            obj.simu = simu;
            obj.bodyNumber = bodynum;
            
            % Wave type

            % linear excitation type
            if obj.waves.typeNum < 10
                obj.excitationMethod = 'no waves';
                obj.excitationMethodNum = 0;
            elseif obj.waves.typeNum >= 10 && obj.waves.typeNum < 20
                obj.excitationMethod = 'regular waves';
                obj.excitationMethodNum = 1;
            elseif obj.waves.typeNum >= 20 && obj.waves.typeNum < 30
                obj.excitationMethod = 'irregular waves';
                obj.excitationMethodNum = 2;
            elseif obj.waves.typeNum >= 30
                obj.excitationMethod = 'user defined waves';
                obj.excitationMethodNum = 3;
            elseif obj.waves.typeNum >= 40
                obj.excitationMethod = 'simple sinusoidal force';
                obj.excitationMethodNum = 4;
                
                obj.simu.nlHydro = 0;
                obj.doLinearDamping = false;
                obj.doViscousDamping = false;
                obj.doMorrisonElementViscousDrag = false;
                obj.doNonLinearFKExcitation = false;
                obj.simu.nlHydro = 0;
                obj.bodyToBodyInteraction = false;
                
            end
            
            
            % Linear Damping
            obj.mbdynLinearDamping = false;
            if obj.simu.linearDamping == 0
                obj.doLinearDamping = false;
            elseif obj.simu.linearDamping == 1
                obj.doLinearDamping = true;
            elseif obj.simu.linearDamping == 2
                obj.doLinearDamping = true;
                obj.mbdynLinearDamping = true;
            end
            
            % Viscous Damping
            obj.mbdynViscousDamping = false;
            if obj.simu.viscousDamping == 0
                obj.doViscousDamping = false;
            elseif obj.simu.viscousDamping == 1
                obj.doViscousDamping = true;
            elseif obj.simu.viscousDamping == 2
                obj.doViscousDamping = true;
                obj.mbdynViscousDamping = true;
            end
                
            % Morrison Element
            if obj.simu.morrisonElement == 0
                obj.doMorrisonElementViscousDrag = false;
            elseif obj.simu.morrisonElement == 1
                obj.doMorrisonElementViscousDrag = true;
            end

            % nonlinear excitation type
            if obj.simu.nlHydro == 0
                obj.doNonLinearFKExcitation = false;
            elseif obj.simu.nlHydro > 0
                obj.doNonLinearFKExcitation = true;
            end

            if obj.simu.nlHydro < 2
                obj.freeSurfaceMethod = 'mean';
                obj.freeSurfaceMethodNum = 0;
            elseif obj.simu.nlHydro == 2
                if isinf (obj.waves.waterDepth)
                    error ('Nonlinear buoyancy cannot be calculated for infinite water depth.');
                end
                obj.freeSurfaceMethod = 'instantaneous';
                obj.freeSurfaceMethodNum = 1;
            end

            % Radiation Damping
            if obj.waves.typeNum == 0 || (obj.waves.typeNum == 10 && obj.simu.ssCalc == 0)%'noWave' & 'regular'
                % constant radiation coefficients
                obj.radiationMethod = 'constant radiation coefficients';
                obj.radiationMethodNum = 0;
            elseif obj.simu.ssCalc == 1
                % state space radiation forces
                obj.radiationMethod = 'state space representation';
                obj.radiationMethodNum = 2;
            elseif obj.simu.ssCalc == 2 || (obj.waves.typeNum == 40)
                % state space radiation forces
                obj.radiationMethod = 'no radiation forces (or handled by external solver)';
                obj.radiationMethodNum = 3;
            else
                % convolution integral radiation forces
                obj.radiationMethod = 'convolution integral';
                obj.radiationMethodNum = 1;
            end
            
            if simu.disableAddedMassForce == true
                obj.disableAddedMassForce = true;
                obj.doAddedMass = false;
            end
            
            if simu.disableRadiationForce == true
                obj.disableRadiationForce = true;
                obj.doRadiationDamping = false;
            end
            
            obj.mbdynAddedMass = false;
            switch lower (obj.simu.addedMassMethod)
                
                case 'extrap'
                    obj.addedMassMethod = 'extrapolate acceleration from previous steps';
                    obj.addedMassMethodNum = 0;
                    
                case 'iterate'
                    obj.addedMassMethod = 'iterate added mass forces at every time step';
                    obj.addedMassMethodNum = 1;
                    
                case 'mbdyn'
                    obj.addedMassMethod = 'use mbdyn added mass element';
                    obj.addedMassMethodNum = 2;
                    obj.mbdynAddedMass = true;
                    
                otherwise
                    error ('Unrecognised addedMassMethod');
                    
            end

            % Body2Body
            if obj.simu.b2b == 0
                obj.bodyToBodyInteraction = false;
            else
                obj.bodyToBodyInteraction = true;
            end

            % first reset everything
            timeDomainSimReset (obj);
            
            obj.bodyTotal = obj.simu.numWecBodies;
            
            if obj.bodyToBodyInteraction == true
                obj.totalLenDOF = 6*obj.bodyTotal;
            else
                obj.totalLenDOF = 6;
            end
            
            % now do the hydro force preprocessing
            obj.hydroForcePre ();
            
            % Radiation Damping
            if obj.radiationMethodNum == 1 && ~isempty (fieldnames(obj.hydroForce))

                % reset the radiation force convolution integral related states
                obj.CIdt = obj.simu.CTTime(2) - obj.simu.CTTime(1);

                obj.radForceVelocity = zeros(obj.totalLenDOF,length(obj.simu.CTTime));

                obj.radForceOldTime = 0;

                obj.radForceOldF_FM = zeros(6,1);

                IRKB_reordered = permute(obj.hydroForce.irkb, [3 1 2]);

                interp_factor = 1;

                obj.radForce_IRKB_interp = IRKB_reordered(:,1:interp_factor:end, :);

            elseif obj.radiationMethodNum == 2

                % initialise the radiation force state space solver object
                obj.radForceSS = stateSpace ( obj.hydroForce.ssRadf.A, ...
                                              obj.hydroForce.ssRadf.B, ...
                                              obj.hydroForce.ssRadf.C, ...
                                              obj.hydroForce.ssRadf.D, ...
                                              zeros (size (obj.hydroForce.ssRadf.A,2), 1) );
                                          
                
                
                % initialise the fixed step integration
                ufcn = @(t, arg2) getVelHist (obj, t);

                obj.radForceSS.initIntegration (obj.simu.startTime, ufcn);
                
            elseif obj.radiationMethodNum == 3
                % do nothing, an external solver is handling the radiation
                % forces
                
            end
            
            adjustMassMatrix(obj);

        end
        
        
        function timeDomainSimReset (obj)
            % resets the body in readiness for a transient simulation
            %
            % Syntax
            %
            % timeDomainSimReset (hb)
            %
            % Desciription
            %
            % timeDomainSimReset resets various internal storeage parameters and
            % settings in preparation for performing a transient simulation
            % based on the ODE solver routines, returning the hydroBody to
            % the state it is in just after calling timeDomainSimSetup. This
            % should be called before re-running a transient simulation
            % with the same parameters.
            %
            % Input
            %
            %   hb - hydroBody object
            %
            %
            
            obj.stepCount = 0;
            
            nsteps = 3;
            
            % reset time history store
            obj.timeStepHist = zeros (1,nsteps);
            
            % reset accel history store (used by added mass calc transport
            % delay)
            if obj.simu.b2b
                obj.accelHist = zeros (nsteps, 6 * obj.simu.numWecBodies);
            else
                obj.accelHist = zeros (nsteps, 6);
            end
            
            if obj.radiationMethodNum == 2
                obj.velHist = obj.accelHist;
            end
            
            % reset wave elevation
            obj.oldElev = [];
            
            obj.oldForce    = [];
            obj.oldWp       = [];
            obj.oldWpMeanFs = [];

            % reset non-linear buoyancy calc stuff
            obj.oldNonLinBuoyancyF = [];
            obj.oldNonLinBuoyancyP = [];

            % reset radiation force related stuff
            if isa (obj.radForceSS, 'stateSpace')
                obj.radForceSS.reset ();
            end

        end
        
        function advanceStep (obj, t, vel, accel)
            % advance to the next time step, accepting the current time
            % step and data into stored solution histories
            %
            % Syntax
            %
            % advanceStep (hb, t, vel, accel)
            %
            % Description
            %
            % advanceStep must be called at the end of each integration
            % time step to update the history of the solution. This is
            % required for the radiation forces when using either the
            % convolution integral method, or the state-space integration
            % using the default internal integration provided by this class
            % (invoked with simu.ssCalc = 1).
            %
            % Input
            %
            %  hb - hydroBody object
            %
            %  t - the last computed time step (the step at which the vel
            %    and accel values are being provided).
            %
            %  vel - vector of velocities and angular velocities, of size
            %    (6 x 1) if there is no body to body interaction (just the
            %    velocities of this body), or size (6*nbodies x 1) if there
            %    is body to body interaction (the velocities of all bodies
            %    in the system).
            %
            %  accel - vector of accelerations and angular accelerations,
            %    of size (6 x 1) if there is no body to body interaction
            %    (just the velocities of this body), or size (6*nbodies x
            %    1) if there is body to body interaction (the accelerations
            %    of all bodies in the system).
            %
            % 
            
            
            obj.timeStepHist = circshift (obj.timeStepHist, [0,-1]);
            
            obj.timeStepHist(end) = t;
            
            % update the acceleration history
            obj.accelHist = circshift (obj.accelHist, [-1,0]);
            
            obj.accelHist(end,:) = accel';
            
            if obj.radiationMethodNum == 2
                % update the velocity history
                obj.velHist = circshift (obj.velHist, [-1,0]);

                obj.velHist(end,:) = vel';
            end
            
            obj.stepCount = obj.stepCount + 1;
            
        end
        
        function vel = getVelHist (obj, t)
            
            if obj.stepCount > 1
                % extrapolate acceleration from previous time steps
                %                     thisaccel = interp1 (obj.timeStepHist', obj.accelHist, t-delay, 'linear', 'extrap');
                
                %                     thisaccel = zeros (size (obj.accelHist,2), 1);
                %                     for ind = 1:numel (thisaccel)
                % %                         thisaccel(ind) = obj.lagrangeinterp (obj.timeStepHist',obj.accelHist(:,ind),t-delay);
                %
                %                         p = polyfit (obj.timeStepHist(end-1:end)', obj.accelHist(end-1:end,ind), 1);
                %                         thisaccel(ind) = polyval (p, t-delay);
                %                     end
                
%                 vel = obj.linearInterp ( obj.timeStepHist(end-1), ...
%                     obj.timeStepHist(end), ...
%                     obj.velHist(end-1,:), ...
%                     obj.velHist(end,:), ...
%                     t );
                
%             elseif obj.stepCount == 2
                vel = interp1 (obj.timeStepHist', obj.velHist, t);
                
            elseif obj.stepCount == 1
                vel = obj.velHist (end,:)';
            end
            
        end
        
        function [forces, breakdown] = hydroForces (obj, t, pos, vel, accel)
            % hydroForces calculates the hydrodynamic forces acting on a
            % body
            %
            % Syntax
            %
            %  [forces, breakdown] = hydroForces (hb, t, x, vel, accel, elv)
            %
            % Input
            %
            %  hb - hydroBody object
            %
            %  t - global simulation time
            %
            %  pos - (6 x 1) displcement of this body in x,y and z and
            %    rotatation around the x, y and z axes
            %
            %  vel - (6 x n) velocities of all bodies in system
            %
            %  accel - (6 x n) acceleration of all bodies in system
            %
            % Output
            %
            %  forces - (6 x 1) forces and moments acting on the body
            %
            %  breakdown - structure containing more detailed
            %    breakdown of the forces acting on the body. The fields
            %    present depend on the simulation settings and can include
            %    the following:
            %
            %    F_ExcitLin : 
            %
            %    F_Excit : 
            %
            %    F_ExcitRamp : 
            %
            %    F_ViscousDamping : 
            %
            %    F_AddedMass : 
            %
            %    F_RadiationDamping : 
            %
            %    F_Restoring : 
            %
            %    BodyHSPressure : 
            %
            %    F_ExcitNonLin : 
            %
            %    WaveNonLinearPressure :
            %
            %    WaveLinearPressure : 
            %
            %    F_MorrisonElement : 
            %
            

            % always do linear excitation forces
            breakdown.F_ExcitLin = linearExcitationForces (obj, t);

            zero_force = zeros (obj.dof, 1);
            
            if obj.doViscousDamping && ~obj.mbdynViscousDamping
                breakdown.F_ViscousDamping = viscousDamping (obj, vel(:,obj.bodyNumber));
            else
                breakdown.F_ViscousDamping = zero_force;
            end
            
            % linear damping
            if obj.doLinearDamping && ~obj.mbdynLinearDamping
                breakdown.F_LinearDamping = linearDampingForce (obj, vel(:,obj.bodyNumber));
            else
                breakdown.F_LinearDamping = zero_force;
            end

            % radiation forces
            if obj.doRadiationDamping
                breakdown.F_RadiationDamping = radiationDampingForces (obj, t, vel);
            else
                breakdown.F_RadiationDamping = zero_force;
            end
            
            if obj.doAddedMass && ~(obj.mbdynAddedMass && obj.noOffDiagonalAddedMassTerms)
                if obj.bodyToBodyInteraction
                    breakdown.F_AddedMass = addedMassForces (obj, t, accel);
                else
                    breakdown.F_AddedMass = addedMassForces (obj, t, accel(:,obj.bodyNumber));
                end
            else
                breakdown.F_AddedMass = zero_force;
            end
            
            % always do hydrostatic restoring forces
            [breakdown.F_Restoring, breakdown.BodyHSPressure, waveElv ] = hydrostaticForces (obj, t, pos);

            if obj.doNonLinearFKExcitation
                
                if isempty (waveElv)
                    % calculate the wave elevation if it has not already
                    % been done by the hydrostaticForces method
                    waveElv = waveElevation (obj, pos, t);
                end

                [ breakdown.F_ExcitNonLin, ...
                  breakdown.WaveNonLinearPressure, ...
                  breakdown.WaveLinearPressure ] = nonlinearExcitationForces (obj, t, pos, waveElv);

            else
                breakdown.F_ExcitNonLin = zero_force;
            end

            if obj.doMorrisonElementViscousDrag

                breakdown.F_MorrisonElement = morrisonElementForce ( obj, t, ...
                                                                     pos(:,obj.bodyNumber), ...
                                                                     vel(:,obj.bodyNumber), ...
                                                                     accel(:,obj.bodyNumber) );
            else

                breakdown.F_MorrisonElement = zero_force;

            end


            breakdown.F_Excit = breakdown.F_ExcitLin + breakdown.F_ExcitNonLin;

            breakdown.F_ExcitRamp = applyRamp (obj, t, breakdown.F_Excit);

            forces = breakdown.F_ExcitRamp ...
                     + breakdown.F_ViscousDamping ...
                     + breakdown.F_AddedMass ...
                     + breakdown.F_Restoring ...
                     + breakdown.F_RadiationDamping ...
                     + breakdown.F_MorrisonElement ...
                     + breakdown.F_LinearDamping;

        end

        function forces = linearDampingForce (obj, vel)
            
%             forces = obj.hydroForce.linearDamping * vel;
            % linear damping is always a diagonal matrix, so just multiply
            % the values along the diagonal
            forces = -obj.linearDamping(:) .* vel;
            
        end
        
        function forces = viscousDamping (obj, vel)

            if obj.diagViscDrag
                forces = -obj.viscDragDiagVals(:) .* ( vel .* abs (vel) );
            else
                forces = -obj.hydroForce.visDrag * ( vel .* abs (vel) );
            end

        end

        function forces = morrisonElementForce (obj, t, pos, vel, accel)
            

            % TODO: in WEC-Sim morrison element stuff uses acceleration delay like added mass forces
            
            % in original WEC-Sim formulation the forces
            switch obj.excitationMethodNum

                case 0
                    % no wave
                    forces = morrisonNoWave (obj, pos, vel, accel);

                case 1
                    % regular wave
                    forces = morrisonRegularWave (obj, t, pos, vel, accel);

                case 2
                    % irregular wave
                    forces = morrisonIrregularWave (obj, t, pos, vel, accel);
                    
                case 3
                    % sinusoidal force
                    forces = zeros (obj.dof, 1);
                    
                case 4
                    % sinusoidal force with CIC
                    forces = zeros (obj.dof, 1);

            end

        end

        function forces = linearExcitationForces (obj, t)
            % calculates linear wave excitation forces during transient
            % simulation
            %
            % Syntax
            %
            % forces = linearExcitationForces (obj, t)
            %
            % Input

            switch obj.excitationMethodNum

                case 0
                    % no wave
                    forces = zeros (obj.dof, 1);

                case 1
                    % regular wave

                    % Calculates the wave force, F_wave, for the case of Regular Waves.

                    % F_wave =   A * cos(w * t) * Re{Fext}
                    %            -  A * sin(w * t) * Im{Fext}

                    wt = obj.waves.w(1,:) .* t;

                    forces = obj.waves.A(1,:) .* ( ...
                                cos (wt) .* obj.hydroForce.fExt.re(1,:) ...
                                - sin (wt) .* obj.hydroForce.fExt.im(1,:) ...
                                                 ).';
                                             
                    % add the precalculated (in hydroForcePre) constant
                    % mean drift force
                    forces = forces + obj.meanDriftForcePreCalc;

                case 2
                    % irregular wave

                    % Calculates the wave force, F_wave, for the case of Irregular Waves.
                    %
                    % F_wave = sum( F_wave(i))
                    %
                    % where i = each frequency bin.

                    % TODO: check correct dimension/orientation of force output
                    A1 = obj.waves.w * t + pi/2;
                    
                    forces = zeros (obj.dof, 1);
                    
                    for wave_dir_ind = 1:length(obj.waves.waveDir)
                        
                        B1 = sin (A1 + obj.waves.phase(:,wave_dir_ind));

                        B11 = sin (obj.waves.w * t + obj.waves.phase(:,wave_dir_ind));

                        C0 = obj.waves.A .* obj.waves.waveSpread(wave_dir_ind) .* obj.waves.dw;

                        C1 = sqrt (obj.waves.A .* obj.waves.waveSpread(wave_dir_ind) .* obj.waves.dw);

                        D0 = squeeze(obj.hydroForce.fExt.md(wave_dir_ind,:,:) .* C0');

                        % hydroForce.fExt.re and im will be a 6 * Nfreqs
                        % matrices, note this statement takes advantage of
                        % automatic broadcasting
                        D1 = obj.hydroForce.fExt.re(wave_dir_ind,:,:) .* C1;

                        D11 = obj.hydroForce.fExt.im(wave_dir_ind,:,:) .* C1;

                        E1 = D0 + B1 .* D1;

                        E11 = B11 .* D11;

                        forces = forces + sum (E1 - E11)';
                    end


                case 3
                    % user defined
                    
                    forces = ppval (obj.hydroForce.userDefinedFeInterp, t);
%                     [ waves.waveAmpTime(:,1), body.hydroForce.userDefinedFe];

                    % Calculates the wave force, F_wave, for the case of User Defined Waves.
                    %
                    % F_wave = convolution calculation [1x6]
%                     error ('not yet implemented')
                    % TODO: make interpolation function for user defined waves, using ppval (C++ version)
                    
                case 4
                    % sinusoidal force

                    % Apply a simple sinusoidally varying force

                    wt = obj.waves.w(obj.bodyNumber) .* t;

                    forces = sin (wt) .* obj.hydroForce.fExt.re(1,:).';

            end

        end

        function [forces, wavenonlinearpressure, wavelinearpressure] = nonlinearExcitationForces (obj, t, pos, elv)
            % calculates the non-linear excitation forces on the body
            
            pos = pos - [ obj.cg; zeros(obj.dof-3, 1)];
            
            [forces, wavenonlinearpressure, wavelinearpressure] = nonFKForce (obj, t, pos, elv);
            
        end

        function F_RadiationDamping = radiationDampingForces (obj, t, vel)
            % calculates the wave radiation forces
            %
            % Syntax
            %
            % F_RadiationDamping = radiationForces (obj, t, vel, accel)
            %
            % Input
            %
            %  t - current simulation time
            %
            %  vel - (6 x 1) translational and angular velocity of the
            %    body, or, if body to body interactions are being
            %    considered, a (6 x n) vector of all the body
            %    velocities.
            %
            % Output
            %
            % F_RadiationDamping - force due to wave radiation damping
            %
            %


            switch obj.radiationMethodNum

                case 0
                    % simple static coefficients
                    if obj.bodyToBodyInteraction
                        F_RadiationDamping = obj.hydroForce.fDamping * vel(:);
                    else
                        F_RadiationDamping = obj.hydroForce.fDamping * vel(:,obj.bodyNumber);
                    end

                case 1
                    % convolution
                    if obj.bodyToBodyInteraction
                        F_RadiationDamping = convolutionIntegral (obj, vel(:), t);
                    else
                        F_RadiationDamping = convolutionIntegral (obj, vel(:,obj.bodyNumber), t);
                    end

                case 2
                    % state space
%                     if obj.simu.b2b
                        F_RadiationDamping = obj.radForceSS.outputs (vel(:));
%                     else
%                         F_RadiationDamping = obj.radForceSS.outputs (vel(:,obj.bodyNumber));
%                     end
                    
                case 3
                    % state space, but calculated by some external solver,
                    % e.g. by supplying MBDyn with the state-space matrices
                    F_RadiationDamping = zeros (obj.dof, 1);

            end
            
            F_RadiationDamping = -F_RadiationDamping;
            

        end
        
        function F_AddedMass = addedMassForces (obj, t, accel)
            % calculates the body added mass forces
            %
            % Syntax
            %
            % F_AddedMass = radiationForces (obj, t, vel, accel)
            %
            % Input
            %
            %  t - current simulation time
            %
            %  accel - (6 x 1) translational and angular acceleration of
            %    the body, or, if body to body interactions are being
            %    considered, a (6 x n) vector of all the body
            %    accelerations.
            %
            % Output
            %
            % F_AddedMass - force due to added mass
            %
            %
            
            % matrix multiplication with acceleration

                
            switch obj.addedMassMethodNum

                case 0

                    delay = 10e-8;
                    if t > (obj.simu.startTime + delay)

                        if obj.stepCount > 2
                            % extrapolate acceleration from previous time steps
        %                     thisaccel = interp1 (obj.timeStepHist', obj.accelHist, t-delay, 'linear', 'extrap');

        %                     thisaccel = zeros (size (obj.accelHist,2), 1);
        %                     for ind = 1:numel (thisaccel)
        % %                         thisaccel(ind) = obj.lagrangeinterp (obj.timeStepHist',obj.accelHist(:,ind),t-delay);
        % 
        %                         p = polyfit (obj.timeStepHist(end-1:end)', obj.accelHist(end-1:end,ind), 1);
        %                         thisaccel(ind) = polyval (p, t-delay);
        %                     end

                        thisaccel = obj.linearInterp ( obj.timeStepHist(end-1), ...
                                                       obj.timeStepHist(end), ...
                                                       obj.accelHist(end-1,:), ...
                                                       obj.accelHist(end,:), ...
                                                       t-delay );

                        elseif obj.stepCount == 2

                            thisaccel = interp1 ( obj.timeStepHist(end-obj.stepCount+1:end)', ....
                                                  obj.accelHist(end-obj.stepCount+1:end,:), ...
                                                  t - delay, ...
                                                  'linear', 'extrap' );

                        elseif obj.stepCount == 1

                            thisaccel = obj.accelHist (end,:)';

                        end

                        F_AddedMass = obj.hydroForce.fAddedMass * thisaccel(:);
        %                 F_AddedMass = obj.hydroForce.fAddedMass * accel(:);
                    else
                        F_AddedMass = zeros (obj.dof, 1);
                    end

                case {1,2}

                    % slower (an assumption, not tested), but mbdyn will
                    % iterate to get the right force
                    F_AddedMass = obj.hydroForce.fAddedMass * accel(:);
                    
%                 case 2
%                     
%                     % added mass is being calculated using the mbdyn added
%                     % mass element, but off-diagonal added mass terms must
%                     % be handled here
%                     F_AddedMass = obj.hydroForce.fAddedMass(1:3,1:3) * accel(1:3);

            end

            F_AddedMass = -F_AddedMass;
                        
        end
        
        function statederivs = radForceSSDerivatives (obj, u)
            
            statederivs = obj.radForceSS.derivatives (u);
            
        end
        
        function status = radForceODEOutputfcn (obj, t, x, flag, varargin)
            % OutputFcn to be called after every completed ode time step
            % when using the state-space representation of the radiation
            % forces
            %
            % Syntax
            %
            % radForceODEOutputfcn (hb, t, x, flag)
            %
            %
            % Input
            %
            %  hb - hydroBody oject
            %
            %  t - current time step
            %
            %  x - state variables at the current time step
            
            status = obj.radForceSS.outputfcn (t, x, flag);
            
        end

        function [forces, body_hspressure_out, waveElv] = hydrostaticForces (obj, t, pos)
            % calculates the hydrostatic forces acting on the body
            
            pos = pos - [ obj.cg; zeros(obj.dof-3, 1) ];
            
            waveElv = [];

            switch obj.freeSurfaceMethodNum

                case 0
                    % linear hydrostatic restoring force

                    body_hspressure_out = [];

                    forces = obj.hydroForce.linearHydroRestCoef * pos;

                    f_gravity = obj.simu.g .* obj.hydroForce.storage.mass;
                    
                    f_buoyancy = obj.simu.rho .* obj.simu.g .*  obj.dispVol;
                    
                    % Add Net Bouyancy Force to Z-Direction
                    forces(3) = forces(3) + (f_gravity - f_buoyancy);
                    
                    forces(4:6) = forces(4:6) + wsim.hydroBody.vcross ([0;0;f_buoyancy], (obj.cb - obj.cg));

                case 1
                    
                    waveElv = waveElevation(obj, pos, t);

                    [forces, body_hspressure_out]  = nonLinearBuoyancy( obj, pos, waveElv, t );

                    % Add Net Bouyancy Force to Z-Direction
                    forces = -forces + [ 0; 0; (obj.simu.g .* obj.hydroForce.storage.mass); 0; 0; 0 ];

            end
            
            % correct the force direction
            forces = -forces;

        end
        
        
        function f = waveElevation(obj, pos, t)
            % calculate the wave elevation at centroids of triangulated surface 
            %
            % NOTE: This function assumes that the STL file is imported
            % with its CG at (0,0,0)

            if obj.freeSurfaceMethodNum == 1
                
                if isempty(obj.oldElev)
                    
                    f = calc_elev (obj, pos, t);
                    
                    obj.oldElev = f;
                    
                else
                    if mod(t, obj.simu.dtFeNonlin) < obj.simu.dt/2
                        
                        f = calc_elev (obj, pos, t);
                        
                        obj.oldElev = f;
                        
                    else
                        f = obj.oldElev;
                    end
                end
                
            else
                f = 0;
            end
        end
        
    end

    % non-public transient simulation methods
    methods (Access = 'protected')

        function ramped = applyRamp (obj, t, nominal)
            % apply a time based ramp function to the input
            %
            % Syntax
            %
            % ramped = applyRamp (hb, t, nominal)
            %
            % Description
            %
            % Applies a ramp function to the input to allow is values to
            % increase gradually over the specified time period. The time
            % period of the ramp is defined in simu.rampT. Within the ramp
            % period, the nominal value supplied is scaled by the value of
            % a function with the profile of a quarter sine wave, going
            % from zero to one over the ramp period.
            %
            % Input
            %
            %  hb - wsim.hydroBody object
            %
            %  t - current 
            %
            %  nominal - quantity to which the ramp function is to be
            %   applied.
            %
            % Output
            %
            %  ramped - scaled value of nominal, zero at t = 0, and equal
            %    to input nominal for t >= ramp period
            %
            % See Also: wsim.hydroBody.hydroForces
            %

            if t < obj.simu.rampT
                % (3 * pi/2) == 4.712388980384690
                ramped  = nominal .* 0.5 .* (1 + sin( pi .* (t ./ obj.simu.rampT) + 4.712388980384690));
            else
                ramped = nominal;
            end

        end

        function [f, wp, wpMeanFS] = nonFKForce (obj, t, pos, elv)
            % calculates the wave excitation force on triangulated surface
            %
            % Syntax
            %
            % [f, wp, wpMeanFS] = nonFKForce (hb, t, pos, elv)
            %
            % Description
            %
            % calculates the wave excitation force and moment on a
            % triangulated surface during a time domain simulation.
            %
            % NOTE: This function assumes that the body represented by the
            % triangle mesh is defined with its CG at (0,0,0), e.g. the STL
            % file for the body is imported with its CG at (0,0,0).
            %
            % Input
            %
            %  hb - wsim.hydroBody object
            %
            %  t - current simulation time
            %
            %  pos - 6 element vector containing the cartesian position and
            %    angular position of the body
            %
            % Output
            %
            %  f - 
            %
            %  wp - 
            %
            %  wpMeanFS - 
            %

            % Logic to calculate nonFKForce at reduced sample time
            if isempty(obj.oldForce) || (mod (t + 1000*eps (t), obj.simu.dtFeNonlin) < obj.simu.dt/2)

                [f, wp, wpMeanFS] = calc_nonFKForce ( obj, pos, elv, t );
                obj.oldForce = f;
                obj.oldWp = wp;
                obj.oldWpMeanFs = wpMeanFS;

            else

                f = obj.oldForce;
                wp = obj.oldWp;
                wpMeanFS = obj.oldWpMeanFs;

            end

        end

        function [f, wp, wpMeanFS] = calc_nonFKForce (obj, pos, elv, t)
            % Function to apply translation and rotation, and calculate
            % forces.

            % Compute new tri coords after cog rotation and translation
            centerMeanFS = obj.offsetXYZ (obj.bodyGeometry.center, obj.hydroData.properties.cg);
            avMeanFS     = obj.bodyGeometry.norm .* [obj.bodyGeometry.area, obj.bodyGeometry.area, obj.bodyGeometry.area];

            % Compute new tri coords after cog rotation and translation
            center = obj.rotateXYZ (obj.bodyGeometry.center, [1 0 0], pos(4));
            center = obj.rotateXYZ (center, [0 1 0], pos(5));
            center = obj.rotateXYZ (center, [0 0 1], pos(6));
            center = obj.offsetXYZ (center, pos(1:3)');
            center = obj.offsetXYZ (center, obj.hydroData.properties.cg);

            % Compute new normal vectors coords after cog rotation and translation
            tnorm = obj.rotateXYZ (obj.bodyGeometry.norm, [1 0 0], pos(4));
            tnorm = obj.rotateXYZ (tnorm, [0 1 0], pos(5));
            tnorm = obj.rotateXYZ (tnorm, [0 0 1], pos(6));

            % Compute area vectors
            av = tnorm .* [obj.bodyGeometry.area, obj.bodyGeometry.area, obj.bodyGeometry.area];

            % Calculate the free surface
            wpMeanFS = pressureDistribution (obj, centerMeanFS, 0, t);

            wp = pressureDistribution (obj, center, elv, t);

            % Calculate forces
            f_linear    = obj.FK ( centerMeanFS,  obj.hydroData.properties.cg,             avMeanFS, wpMeanFS );
            f_nonLinear = obj.FK ( center,        pos(1:3)' + obj.hydroData.properties.cg,  av,       wp );
            f = f_nonLinear - f_linear;

        end

        function f = pressureDistribution (obj, center, elv, t)
            % calculate pressure distribution
            %
            % Syntax
            %
            % f = pressureDistribution (hb, center, elv, t)
            %
            % Description
            %
            % Calculates a pressure distribution 
            %
            % Input
            %
            %  hb - wsim.hydroBody object
            %
            %  center - (n x 3) matrix of coordinated at which the
            %    distribution is to be calculated
            %
            %  elv - (n x 1) array of values of the wave elevation at each
            %    point in 'centre'
            %
            % Output
            %
            %  f - (n x 1) array of values of the pressure distribution at
            %    each point in 'centre'.
            %
            % See Also: 
            %

            % preallocate array for results
            f = zeros (size (center, 1), 1);
            
            % z is vertical position of the point relative to the mean
            % water surface
            z = zeros (size (center, 1), 1);

            % TODO: use logical indexing and only calculate the forces for points where z <= 0 
            % TODO: see final statement in function, f(z > 0) = 0; )
            if obj.waves.typeNum < 10

            elseif obj.waves.typeNum < 20

                f = obj.simu.rho ...
                    .* obj.simu.g ...
                    .* obj.waves.A(1) ...
                    .* cos ( obj.waves.k(1) .* center(:,1) - obj.waves.w(1) * t );

                if obj.waves.deepWaterWave == 0

                    z = (center(:,3) - elv) ...
                        .* obj.waves.waterDepth ...
                        ./ (obj.waves.waterDepth + elv);

                    f = f .* ( cosh ( obj.waves.k(1) .* (z + obj.waves.waterDepth) ) ...
                                ./ cosh (obj.waves.k(1) * obj.waves.waterDepth ) ...
                             );

                else

                    z = (center(:,3) - elv);

                    f = f .* exp(obj.waves.k(1) .* z);

                end

            elseif obj.waves.typeNum < 30

                for i = 1:length(obj.waves.A)

                    if obj.waves.deepWaterWave == 0 ...
                            && obj.waves.waterDepth <= 0.5*pi/obj.waves.k(i)

                        z = ( center(:,3) - elv ) ...
                            .* obj.waves.waterDepth ...
                            ./ ( obj.waves.waterDepth + elv );

                        f_tmp = obj.simu.rho ...
                                .* obj.simu.g ...
                                .* sqrt (obj.waves.A(i) * obj.waves.dw(i)) ...
                                .* cos ( obj.waves.k(i) .* center(:,1) ...
                                         - obj.waves.w(i) * t ...
                                         - obj.waves.phase(i) ...
                                       );

                        f = f + f_tmp .* ( cosh ( obj.waves.k(i) .* (z + obj.waves.waterDepth) ) ...
                                           ./ cosh ( obj.waves.k(i) .* obj.waves.waterDepth ) ...
                                         );

                    else

                        z = (center(:,3) - elv);

                        f_tmp = obj.simu.rho ...
                                .* obj.simu.g ...
                                .* sqrt (obj.waves.A(i) * obj.waves.dw(i)) ...
                                .* cos ( obj.waves.k(i) .* center(:,1) ...
                                         - obj.waves.w(i) * t - obj.waves.phase(i) ...
                                       );

                        f = f + f_tmp .* exp (obj.waves.k(i) .* z);

                    end
                end

            end

            f(z > 0) = 0;

        end

        function f = FK(obj, center, instcg, av, wp)
            % Function to calculate the force and moment about the cog due
            % to Froude-Krylov pressure

            f = zeros(6,1);

            % Calculate the hydrostatic pressure at each triangle center
            pressureVect = [wp, wp, wp] .* -av;

            % Compute force about cog
            f(1:3) = sum (pressureVect);

            % Compute moment about cog
            tmp1 = ones (length (center(:,1)), 1);
%             tmp2 = tmp1 * instcg'; orig
            tmp2 = tmp1 * instcg;
            center2cgVec = center - tmp2;

            % TODO: can cross here be replace by faster obj.vcross?
            f(4:6) = sum (cross (center2cgVec, pressureVect));
        end

        function F_FM = convolutionIntegral(obj, vel, t)
            % Function to calculate convolution integral

            % TODO: we could use advanceStep to ensure histories are
            % updated properly instead of the following test
            % TODO: allow nonuniform time spacing for convolution integral
            if abs(t - obj.radForceOldTime - obj.CIdt) < 1e-8

                obj.radForceVelocity = circshift(obj.radForceVelocity, 1, 2);

                obj.radForceVelocity(:,1) = vel(:);

                % integrate
                time_series = bsxfun (@times, obj.radForce_IRKB_interp, obj.radForceVelocity);

                F_FM = squeeze (trapz (obj.simu.CTTime, sum (time_series, 1)));

                obj.radForceOldF_FM = F_FM;

                obj.radForceOldTime = t;
            else
                % use the old value which at the start of a simulation
                % is always zeros
                F_FM = obj.radForceOldF_FM;
            end

        end

        function [f,p]  = nonLinearBuoyancy (obj, pos, elv, t)
            % Function to calculate buoyancy force and moment on a
            % triangulated surface NOTE: This function assumes that the STL
            % file is imported with its CG at 0,0,0

            if isempty(obj.oldNonLinBuoyancyF)

                [f,p] = calc_nonLinearBuoyancy (obj, pos, elv);

                obj.oldNonLinBuoyancyF  = f;

                obj.oldNonLinBuoyancyP  = p;

            else

                if mod(t, obj.simu.dtFeNonlin) < obj.simu.dt/2

                    [f,p] = calc_nonLinearBuoyancy (obj, pos,elv);

                    obj.oldNonLinBuoyancyF  = f;

                    obj.oldNonLinBuoyancyP  = p;

                else

                    f  = obj.oldNonLinBuoyancyF;

                    p  = obj.oldNonLinBuoyancyP;

                end
            end
        end

        function [f,p] = calc_nonLinearBuoyancy (obj, pos, elv)
            % Function to apply translation and rotation and calculate forces

            % Compute new tri coords after cog rotation and translation
            center = obj.rotateXYZ(obj.bodyGeometry.center, [1 0 0], pos(4));
            center = obj.rotateXYZ(center, [0 1 0], pos(5));
            center = obj.rotateXYZ(center, [0 0 1], pos(6));
            center = obj.offsetXYZ(center, pos(1:3)');
            center = obj.offsetXYZ(center, obj.cg');

            % Compute new normal vectors coords after cog rotation
            tnorm = obj.rotateXYZ(obj.bodyGeometry.norm, [1 0 0], pos(4));
            tnorm = obj.rotateXYZ(tnorm, [0 1 0], pos(5));
            tnorm = obj.rotateXYZ(tnorm, [0 0 1], pos(6));

            % Calculate the hydrostatic forces
            av = tnorm .* [obj.bodyGeometry.area, obj.bodyGeometry.area, obj.bodyGeometry.area];

            [f,p] = fHydrostatic (obj, center, elv, pos(1:3) + obj.cg, av);

        end

        function [f,p] = fHydrostatic(obj, center, elv, instcg, av)
            % Function to calculate the force and moment about the cog due
            % to hydrostatic pressure
            f = zeros(6,1);

            % Zero out regions above the mean free surface
            z = center(:,3); z((z-elv)>0)=0;

            % Calculate the hydrostatic pressure at each triangle center
            pressureVect = obj.simu.rho * obj.simu.g .* [-z -z -z] .* -av;
            p = obj.simu.rho * obj.simu.g .* -z;

            % Compute force about cog
            f(1:3) = sum(pressureVect);

            tmp1 = ones(length(center(:,1)),1);
            tmp2 = tmp1*instcg';
            center2cgVec = center - tmp2;
            % TODO: can cross here be replace by faster obj.vcross?
            f(4:6)= sum(cross(center2cgVec,pressureVect));
        end
        
        function f = calc_elev(obj, pos, t)
            % Function to rotate and translate body and call wave elevation function at new locations 

            % Compute new tri center coords after cog rotation and translation
            center = obj.rotateXYZ (obj.bodyGeometry.center, [1, 0, 0], pos(4));
            center = obj.rotateXYZ (center, [0, 1, 0], pos(5));
            center = obj.rotateXYZ (center, [0, 0, 1], pos(6));
            center = obj.offsetXYZ (center, pos(1:3)');
            center = obj.offsetXYZ (center, obj.cg');
            
            % Calculate the free surface
            f = waveElev (obj, center,t);
        end
        
        function f = waveElev (obj, center, t)
            % Function to calculate the wave elevation at an array of points
            
            f = zeros(length(center(:,3)),1);
            
            cx = center(:,1);
            cy = center(:,2);
            
            X = cx * cos (obj.waves.waveDir * pi/180) ...
                + cy * sin (obj.waves.waveDir * pi/180);
            
            if obj.waves.typeNum <10
                
            elseif obj.waves.typeNum <20
                
                f = obj.waves.A(1) .* cos(obj.waves.k(1) .* X - obj.waves.w(1) * t);
                
            elseif obj.waves.typeNum <30
                
                tmp = sqrt (obj.waves.A .* obj.waves.dw);
                
                tmp1 = ones (1, length (center(:,1)));
                
                tmp2 = (obj.waves.w .* t + obj.waves.phase) * tmp1;
                
                tmp3 = cos (obj.waves.k * X'- tmp2);
                
                f(:,1) = tmp3' * tmp;
                
            end
            
            % apply ramp if we are not past the initial ramp time
            f = applyRamp (obj, t, f);
%             if t <= obj.simu.rampT
%                 rampF = (1 + cos (pi + pi * t / obj.simu.rampT)) / 2;
%                 f = f .* rampF;
%             end
        end
        
        function f = morrisonRegularWave (obj, t, pos, vel, accel)
            
            [rr,~] = size(obj.morrisonElement.rgME);
            
            FMt = zeros(rr,6);
            
            for ii = 1:rr
                
                % Calculate Rotation Matrix
                RotMax = [  cos(pos(5))*cos(pos(6)), cos(pos(4))*sin(pos(6)) + sin(pos(4))*sin(pos(5))*cos(pos(6)) , sin(pos(4))*sin(pos(6)) - cos(pos(4))*sin(pos(5))*sin(pos(6)); ...
                           -cos(pos(5))*sin(pos(6)), cos(pos(4))*cos(pos(6)) -  sin(pos(4))*sin(pos(5))*sin(pos(6)), sin(pos(4))*cos(pos(6)) + cos(pos(4))*sin(pos(5))*sin(pos(6)); ...
                            sin(pos(5))             , -sin(pos(4))*cos(pos(5))                                         , cos(pos(4))*cos(pos(5)) ...
                         ];
                      
                % Rotate Cartesian
                rRot    = mtimes(obj.morrisonElement.rgME(ii,:),RotMax);
                Dispt   = [pos(1),pos(2),pos(3)];
                ShiftCg = Dispt + rRot;
                
                % Update translational and rotational velocity
                % w refers to \omega = rotational velocity
                Velt    = [vel(4),vel(5),vel(6)];
                wxr     = cross(Velt,obj.morrisonElement.rgME(ii,:)); % TODO: can cross here be replace by faster obj.vcross?
                
                % Vel should be a column vector
                Vel2    = [vel(1),vel(2),vel(3)] + wxr;
                
                % Update translational and rotational acceleration
                % dotw refers to \dot{\omega} = rotational acceleration
                Accelt  = [accel(4),accel(5),accel(6)];
                dotwxr  = cross(Accelt,obj.morrisonElement.rgME(ii,:)); % TODO: can cross here be replace by faster obj.vcross?
                wxwxr   = cross(Velt,wxr); % TODO: can cross here be replace by faster obj.vcross?
                Accel2  = [accel(1),accel(2),accel(3)] + dotwxr + wxwxr;
                
                % Calculate Orbital Velocity
                waveDirRad     = obj.waves.waveDir*pi/180;
                phaseArg       = obj.waves.w*t - obj.waves.k*(ShiftCg(1)*cos(waveDirRad) + ShiftCg(2)*sin(waveDirRad));
                
                % Vertical Variation
                kh              = obj.waves.k*obj.waves.waterDepth;
                kz              = obj.waves.k*ShiftCg(3);
                if kh > pi  % Deep water wave
                    coeffHorz  = exp(kz);
                    coeffVert  = coeffHorz;
                else        % Shallow & Intermediate Depth
                    coeffHorz  = cosh(kz + kh)/cosh(kh);
                    coeffVert  = sinh(kz + kh)/cosh(kh);
                end
                
                
                % TODo: could use obj.applyRamp here
                % Ramp Time
                ramp = applyRamp (obj, t, obj.waves.A);
%                 if Time <= rampTime
%                     ramp        = (obj.waves.A/2)*(1 + cos( pi + pi/rampTime*Time));
%                 else
%                     ramp        = obj.waves.A;
%                 end
                
                % Orbital Velocity
                uV              =  ramp*coeffHorz*cos(phaseArg)*obj.simu.g*obj.waves.k*(1/obj.waves.w)*cos(waveDirRad);
                vV              =  ramp*coeffHorz*cos(phaseArg)*obj.simu.g*obj.waves.k*(1/obj.waves.w)*sin(waveDirRad);
                wV              = -ramp*coeffVert*sin(phaseArg)*obj.simu.g*obj.waves.k*(1/obj.waves.w);
                
                % Orbital Acceleration
                uA              = -ramp*coeffHorz*sin(phaseArg)*obj.simu.g*obj.waves.k*cos(waveDirRad);
                vA              = -ramp*coeffHorz*sin(phaseArg)*obj.simu.g*obj.waves.k*sin(waveDirRad);
                wA              = -ramp*coeffVert*cos(phaseArg)*obj.simu.g*obj.waves.k;
                
                %  ****      Added inertia and drag forces      ****
                areaRot         = abs(mtimes(obj.morrisonElement.characteristicArea(ii,:),RotMax));
                CdRot           = mtimes(abs(obj.morrisonElement.cd(ii,:)),RotMax);
                CaRot           = abs(mtimes(obj.morrisonElement.ca(ii,:),RotMax));
                
                % Forces from velocity drag
                uVdiff          = uV - Vel2(1); FxuV = (1/2)*abs(uVdiff)*uVdiff*obj.simu.rho*CdRot(1)*areaRot(1);
                vVdiff          = vV - Vel2(2); FxvV = (1/2)*abs(vVdiff)*vVdiff*obj.simu.rho*CdRot(2)*areaRot(2);
                wVdiff          = wV - Vel2(3); FxwV = (1/2)*abs(wVdiff)*wVdiff*obj.simu.rho*CdRot(3)*areaRot(3);
                
                % Forces from body acceleration inertia
                uAdiff          = uA - Accel2(1); FxuA = uAdiff*obj.simu.rho*obj.morrisonElement.VME(ii,:)*CaRot(1);
                vAdiff          = vA - Accel2(2); FxvA = vAdiff*obj.simu.rho*obj.morrisonElement.VME(ii,:)*CaRot(2);
                wAdiff          = wA - Accel2(3); FxwA = wAdiff*obj.simu.rho*obj.morrisonElement.VME(ii,:)*CaRot(3);
                
                % Forces from fluid acceleration inertia
                FxuAf           = uA*obj.morrisonElement.VME(ii,:)*obj.simu.rho;
                FxvAf           = vA*obj.morrisonElement.VME(ii,:)*obj.simu.rho;
                FxwAf           = wA*obj.morrisonElement.VME(ii,:)*obj.simu.rho;
                
                % Sum the three force contributions
                if ShiftCg(3) > 0
                    F           = [0, 0, 0];
                    M           = [0, 0, 0];
                    FMt(ii,:)   = [F,M];
                else
                    F           = [FxuV + FxuA + FxuAf,...
                        FxvV + FxvA + FxvAf,...
                        FxwV + FxwA + FxwAf];
                    M           = cross(rRot,F); % TODO: can cross here be replace by faster obj.vcross?
                    FMt(ii,:)   = [F,M];
                end
            end
            
            f  = [ sum(FMt(:,1)); 
                   sum(FMt(:,2));
                   sum(FMt(:,3));
                   sum(FMt(:,4));
                   sum(FMt(:,5));
                   sum(FMt(:,6)) ];
            
        end
        
        function f = morrisonIrregularWave (obj, t, pos, vel, accel)
            
            [rr,~]  = size(obj.morrisonElement.rgME); 
            ff    = length(obj.waves.w);
            FMt     = zeros(rr,6);
            uVt     = zeros(ff,1); vVt = uVt; wVt = vVt; uAt = wVt; vAt = uAt; wAt = vAt;
            for ii = 1:rr
                % Calculate Rotation Matrix
                RotMax = [ cos(pos(5))*cos(pos(6)),  cos(pos(4))*sin(pos(6)) + sin(pos(4))*sin(pos(5))*cos(pos(6)) , sin(pos(4))*sin(pos(6)) - cos(pos(4))*sin(pos(5))*sin(pos(6));...
                          -cos(pos(5))*sin(pos(6)),  cos(pos(4))*cos(pos(6)) -  sin(pos(4))*sin(pos(5))*sin(pos(6)), sin(pos(4))*cos(pos(6)) + cos(pos(4))*sin(pos(5))*sin(pos(6));...
                           sin(pos(5))            , -sin(pos(4))*cos(pos(5))                                       , cos(pos(4))*cos(pos(5))                                        ];
                % Rotate Cartesian
                rRot    = mtimes(obj.morrisonElement.rgME(ii,:),RotMax);
                Dispt   = [pos(1),pos(2),pos(3)];
                ShiftCg = Dispt + rRot;
                % Update translational and rotational velocity
                % w refers to \omega = rotational velocity
                Velt    = [vel(4),vel(5),vel(6)];
                wxr     = cross(Velt,obj.morrisonElement.rgME(ii,:)); % TODO: can cross here be replace by faster obj.vcross?
                % Update Translational Velocity
                Vel2    = [vel(1),vel(2),vel(3)] + wxr;
                % Update translational and rotational acceleration
                % dotw refers to \dot{\omega} = rotational acceleration
                Accelt  = [accel(4),accel(5),accel(6)];
                dotwxr  = cross(Accelt,obj.morrisonElement.rgME(ii,:)); % TODO: can cross here be replace by faster obj.vcross?
                wxwxr   = cross(Velt,wxr); % TODO: can cross here be replace by faster obj.vcross?
                % Update Translational Acceleration
                Accel2  = [accel(1),accel(2),accel(3)] + dotwxr + wxwxr;
                %% Calculate Orbital Velocity
                for jj = 1:ff
                    waveDirRad      = obj.waves.waveDir*pi/180;
                    phaseArg        = obj.waves.w(jj,1)*t - obj.waves.k(jj,1)*(ShiftCg(1)*cos(waveDirRad) + ShiftCg(2)*sin(waveDirRad)) + obj.waves.phase(jj,1);
                    % Vertical Variation
                    kh              = obj.waves.k(jj,1)*obj.waves.waterDepth;
                    kz              = obj.waves.k(jj,1)*ShiftCg(3);
                    if kh > pi % Deep Water Wave
                        coeffHorz  = exp(kz);
                        coeffVert  = coeffHorz;
                    else % Shallow & Intermediate depth
                        coeffHorz  = cosh(kz + kh)/cosh(kh);
                        coeffVert  = sinh(kz + kh)/cosh(kh);
                    end
                    % Ramp Time
                    ramp = applyRamp (obj, t, sqrt(obj.waves.A(jj,1)*obj.waves.dw(jj,1)));
%                     if Time <= rampTime
%                         ramp        = (sqrt(obj.waves.A(jj,1)*dw(jj,1))/2)*(1 + cos(pi + pi/rampTime*Time));
%                     else
%                         ramp        = sqrt(obj.waves.A(jj,1)*dw(jj,1));
%                     end

                    % Orbital Velocity for each individual wave component
                    uVt(jj,1)       =  ramp*coeffHorz*cos(phaseArg)*obj.simu.g*obj.waves.k(jj,1)*(1/obj.waves.w(jj,1))*cos(waveDirRad);
                    vVt(jj,1)       =  ramp*coeffHorz*cos(phaseArg)*obj.simu.g*obj.waves.k(jj,1)*(1/obj.waves.w(jj,1))*sin(waveDirRad);
                    wVt(jj,1)       = -ramp*coeffVert*sin(phaseArg)*obj.simu.g*obj.waves.k(jj,1)*(1/obj.waves.w(jj,1));
                    % Orbital Acceleration for each individual wave component
                    uAt(jj,1)       = -ramp*coeffHorz*sin(phaseArg)*obj.simu.g*obj.waves.k(jj,1)*cos(waveDirRad);
                    vAt(jj,1)       = -ramp*coeffHorz*sin(phaseArg)*obj.simu.g*obj.waves.k(jj,1)*sin(waveDirRad);
                    wAt(jj,1)       = -ramp*coeffVert*cos(phaseArg)*obj.simu.g*obj.waves.k(jj,1);
                end
                % Sum the wave components to obtain the x, y, z orbital velocities
                uV = sum(uVt); uA = sum(uAt); vV = sum(vVt); vA = sum(vAt); wV = sum(wVt); wA = sum(wAt);
                %% Added inertia and drag forces
                areaRot         = abs(mtimes(obj.morrisonElement.characteristicArea(ii,:),RotMax));
                CdRot           = mtimes(abs(obj.morrisonElement.cd(ii,:)),RotMax);
                CaRot           = abs(mtimes(obj.morrisonElement.ca(ii,:),RotMax));
                % Forces from velocity drag
                uVdiff          = uV - Vel2(1); FxuV = (1/2)*abs(uVdiff)*uVdiff*obj.simu.rho*CdRot(1)*areaRot(1);
                vVdiff          = vV - Vel2(2); FxvV = (1/2)*abs(vVdiff)*vVdiff*obj.simu.rho*CdRot(2)*areaRot(2);
                wVdiff          = wV - Vel2(3); FxwV = (1/2)*abs(wVdiff)*wVdiff*obj.simu.rho*CdRot(3)*areaRot(3);
                % Forces from body acceleration inertia
                uAdiff          = uA - Accel2(1); FxuA = uAdiff*obj.simu.rho*obj.morrisonElement.VME(ii,:)*CaRot(1);
                vAdiff          = vA - Accel2(2); FxvA = vAdiff*obj.simu.rho*obj.morrisonElement.VME(ii,:)*CaRot(2);
                wAdiff          = wA - Accel2(3); FxwA = wAdiff*obj.simu.rho*obj.morrisonElement.VME(ii,:)*CaRot(3);
                % Forces from fluid acceleration inertia
                FxuAf           = uA*obj.morrisonElement.VME(ii,:)*obj.simu.rho;
                FxvAf           = vA*obj.morrisonElement.VME(ii,:)*obj.simu.rho;
                FxwAf           = wA*obj.morrisonElement.VME(ii,:)*obj.simu.rho;
                % Combine the forces and moments
                if ShiftCg(3) > 0
                    F           = [0, 0, 0];
                    M           = [0, 0, 0];
                    FMt(ii,:)   = [F,M];
                else
                    F           = [ FxuV + FxuA + FxuAf,...
                                    FxvV + FxvA + FxvAf,...
                                    FxwV + FxwA + FxwAf];
                    M           = cross(rRot,F); % TODO: can cross here be replace by faster obj.vcross?
                    FMt(ii,:)   = [F,M];
                end
            end
            
            f  = [ sum(FMt(:,1));
                   sum(FMt(:,2));
                   sum(FMt(:,3));
                   sum(FMt(:,4));
                   sum(FMt(:,5));
                   sum(FMt(:,6)) ];
            
        end
        
        function f = morrisonNoWave (obj, pos, vel, accel)
            
            [rr,~]=size(obj.morrisonElement.rgME);
            FMt = zeros(rr,6);
            for ii = 1:rr
                % Calculate Rotation Matrix
                RotMax = [ cos(pos(5))*cos(pos(6)),  cos(pos(4))*sin(pos(6)) + sin(pos(4))*sin(pos(5))*cos(pos(6)) , sin(pos(4))*sin(pos(6)) - cos(pos(4))*sin(pos(5))*sin(pos(6));...
                          -cos(pos(5))*sin(pos(6)),  cos(pos(4))*cos(pos(6)) -  sin(pos(4))*sin(pos(5))*sin(pos(6)), sin(pos(4))*cos(pos(6)) + cos(pos(4))*sin(pos(5))*sin(pos(6));...
                           sin(pos(5))            , -sin(pos(4))*cos(pos(5))                                       , cos(pos(4))*cos(pos(5))                                        ];
                % Rotate Cartesian
                rRot    = mtimes(obj.morrisonElement.rgME(ii,:),RotMax);
                Dispt   = [pos(1),pos(2),pos(3)];
                ShiftCg = Dispt + rRot;
                % Update translational and rotational velocity
                Velt    = [vel(4),vel(5),vel(6)];                       % w refers to \omega = rotational velocity
                wxr     = cross(Velt,obj.morrisonElement.rgME(ii,:)); % TODO: can cross here be replace by faster obj.vcross?
                %Vel should be a column vector
                Vel2    = [vel(1),vel(2),vel(3)] + wxr;
                % Update translational and rotational acceleration
                Accelt  = [accel(4),accel(5),accel(6)];
                dotwxr  = cross(Accelt,obj.morrisonElement.rgME(ii,:));                        % dotw refers to \dot{\omega} = rotational acceleration
                wxwxr   = cross(Velt,wxr); % TODO: can cross here be replace by faster obj.vcross?
                Accel2  = [accel(1),accel(2),accel(3)] + dotwxr + wxwxr;
                %% Added inertia and drag forces
                areaRot = abs(mtimes(obj.morrisonElement.characteristicArea(ii,:),RotMax));
                CdRot   = mtimes(abs(obj.morrisonElement.cd(ii,:)),RotMax);
                CaRot   = abs(mtimes(obj.morrisonElement.ca(ii,:),RotMax));
                % Forces from body velocity drag
                FxuV    = (1/2)*abs(-1*Vel2(1))*-1*Vel2(1)*obj.simu.rho*CdRot(1)*areaRot(1);
                FxvV    = (1/2)*abs(-1*Vel2(2))*-1*Vel2(2)*obj.simu.rho*CdRot(2)*areaRot(2);
                FxwV    = (1/2)*abs(-1*Vel2(3))*-1*Vel2(3)*obj.simu.rho*CdRot(3)*areaRot(3);
                % Forces from body acceleration inertia
                FxuA = obj.simu.rho*obj.morrisonElement.VME(ii,:)*CaRot(1)*-1*Accel2(1);
                FxvA = obj.simu.rho*obj.morrisonElement.VME(ii,:)*CaRot(2)*-1*Accel2(2);
                FxwA = obj.simu.rho*obj.morrisonElement.VME(ii,:)*CaRot(3)*-1*Accel2(3);
                % Sum the force and moment contributions
                if ShiftCg(3) > 0
                    FMt(ii,:)   = [0, 0, 0, 0, 0, 0];
                else
                    F           = [ FxuV + FxuA,...
                                    FxvV + FxvA,...
                                    FxwV + FxwA];
                    M           = cross(rRot,F); % TODO: can cross here be replace by faster obj.vcross?
                    FMt(ii,:)   = [F,M];
                end
            end
            
            f  = [ sum(FMt(:,1));
                   sum(FMt(:,2));
                   sum(FMt(:,3));
                   sum(FMt(:,4));
                   sum(FMt(:,5));
                   sum(FMt(:,6)) ];
            
        end

    end

	% public post-processing related methods
    methods (Access = 'public') %modify object = F; output = T

        function fam = forceAddedMass(obj,acc,B2B)
            % Recomputes the real added mass force time history for the
            % body
            %
            % Syntax
            %
            % fam = forceAddedMass(hb,acc,B2B)
            %
            % Input
            %
            %  hb - hydroBody object
            %
            %  acc - (n x 6) time history of body accelerations for which
            %   the added mass is to be recalculated
            %
            %  B2B - flag indicating whether body-to-body interactions are
            %    present
            %
            % Output
            %
            %  fam - added mass recalculated from time history of
            %    accelerations and body added mass.
            %
            %
            
            iBod = obj.bodyNumber;
            fam = zeros(size(acc));
            for i =1:6
                tmp = zeros(length(acc(:,i)),1);
                for j = 1:6
                    if B2B == 1
                        jj = (iBod-1)*6+j;
                    else
                        jj = j;
                    end
                    iam = obj.hydroForce.fAddedMass(i,jj);
                    tmp = tmp + acc(:,j) .* iam;
                end
                fam(:,i) = tmp;
            end
        end

        function write_paraview_vtp (obj, t, pos_all, bodyname, model, simdate, hspressure, wavenonlinearpressure, wavelinearpressure)
            % Writes vtp files for visualization with ParaView
            numVertex = obj.bodyGeometry.numVertex;
            numFace = obj.bodyGeometry.numFace;
            vertex = obj.bodyGeometry.vertex;
            face = obj.bodyGeometry.face;
            cellareas = obj.bodyGeometry.area;
            for it = 1:length(t)
                % calculate new position
                pos = pos_all(it,:);
                vertex_mod = wsim.hydroBody.rotateXYZ(vertex,[1 0 0],pos(4));
                vertex_mod = wsim.hydroBody.rotateXYZ(vertex_mod,[0 1 0],pos(5));
                vertex_mod = wsim.hydroBody.rotateXYZ(vertex_mod,[0 0 1],pos(6));
                vertex_mod = wsim.hydroBody.offsetXYZ(vertex_mod,pos(1:3));
                % open file
                filename = ['vtk' filesep 'body' num2str(obj.bodyNumber) '_' bodyname filesep bodyname '_' num2str(it) '.vtp'];
                fid = fopen(filename, 'w');
                % write header
                fprintf(fid, '<?xml version="1.0"?>\n');
                fprintf(fid, ['<!-- WEC-Sim Visualization using ParaView -->\n']);
                fprintf(fid, ['<!--   model: ' model ' - ran on ' simdate ' -->\n']);
                fprintf(fid, ['<!--   body:  ' bodyname ' -->\n']);
                fprintf(fid, ['<!--   time:  ' num2str(t(it)) ' -->\n']);
                fprintf(fid, '<VTKFile type="PolyData" version="0.1">\n');
                fprintf(fid, '  <PolyData>\n');
                % write body info
                fprintf(fid,['    <Piece NumberOfPoints="' num2str(numVertex) '" NumberOfPolys="' num2str(numFace) '">\n']);
                % write points
                fprintf(fid,'      <Points>\n');
                fprintf(fid,'        <DataArray type="Float32" NumberOfComponents="3" format="ascii">\n');
                for ii = 1:numVertex
                    fprintf(fid, '          %5.5f %5.5f %5.5f\n', vertex_mod(ii,:));
                end
                clear vertex_mod
                fprintf(fid,'        </DataArray>\n');
                fprintf(fid,'      </Points>\n');
                % write tirangles connectivity
                fprintf(fid,'      <Polys>\n');
                fprintf(fid,'        <DataArray type="Int32" Name="connectivity" format="ascii">\n');
                for ii = 1:numFace
                    fprintf(fid, '          %i %i %i\n', face(ii,:)-1);
                end
                fprintf(fid,'        </DataArray>\n');
                fprintf(fid,'        <DataArray type="Int32" Name="offsets" format="ascii">\n');
                fprintf(fid, '         ');
                for ii = 1:numFace
                    n = ii * 3;
                    fprintf(fid, ' %i', n);
                end
                fprintf(fid, '\n');
                fprintf(fid,'        </DataArray>\n');
                fprintf(fid, '      </Polys>\n');
                % write cell data
                fprintf(fid,'      <CellData>\n');
                % Cell Areas
                fprintf(fid,'        <DataArray type="Float32" Name="Cell Area" NumberOfComponents="1" format="ascii">\n');
                for ii = 1:numFace
                    fprintf(fid, '          %i', cellareas(ii));
                end
                fprintf(fid, '\n');
                fprintf(fid,'        </DataArray>\n');
                % Hydrostatic Pressure
                if ~isempty(hspressure)
                    fprintf(fid,'        <DataArray type="Float32" Name="Hydrostatic Pressure" NumberOfComponents="1" format="ascii">\n');
                    for ii = 1:numFace
                        fprintf(fid, '          %i', hspressure.signals.values(it,ii));
                    end
                    fprintf(fid, '\n');
                    fprintf(fid,'        </DataArray>\n');
                end
                % Non-Linear Froude-Krylov Wave Pressure
                if ~isempty(wavenonlinearpressure)
                    fprintf(fid,'        <DataArray type="Float32" Name="Wave Pressure NonLinear" NumberOfComponents="1" format="ascii">\n');
                    for ii = 1:numFace
                        fprintf(fid, '          %i', wavenonlinearpressure.signals.values(it,ii));
                    end
                    fprintf(fid, '\n');
                    fprintf(fid,'        </DataArray>\n');
                end
                % Linear Froude-Krylov Wave Pressure
                if ~isempty(wavelinearpressure)
                    fprintf(fid,'        <DataArray type="Float32" Name="Wave Pressure Linear" NumberOfComponents="1" format="ascii">\n');
                    for ii = 1:numFace
                        fprintf(fid, '          %i', wavelinearpressure.signals.values(it,ii));
                    end
                    fprintf(fid, '\n');
                    fprintf(fid,'        </DataArray>\n');
                end
                fprintf(fid,'      </CellData>\n');
                % end file
                fprintf(fid, '    </Piece>\n');
                fprintf(fid, '  </PolyData>\n');
                fprintf(fid, '</VTKFile>');
                % close file
                fclose(fid);
            end
        end

    end

    % Static methods
    methods (Static)

        function xn = rotateXYZ (x, ax, theta)
            % Function to rotate a point about an arbitrary axis
            % x: 3-componenet coordinates
            % ax: axis about which to rotate (must be a normal vector)
            % theta: rotation angle
            % xn: new coordinates after rotation
            rotMat = zeros(3);
            rotMat(1,1) = ax(1)*ax(1)*(1-cos(theta))    + cos(theta);
            rotMat(1,2) = ax(2)*ax(1)*(1-cos(theta))    + ax(3)*sin(theta);
            rotMat(1,3) = ax(3)*ax(1)*(1-cos(theta))    - ax(2)*sin(theta);
            rotMat(2,1) = ax(1)*ax(2)*(1-cos(theta))    - ax(3)*sin(theta);
            rotMat(2,2) = ax(2)*ax(2)*(1-cos(theta))    + cos(theta);
            rotMat(2,3) = ax(3)*ax(2)*(1-cos(theta))    + ax(1)*sin(theta);
            rotMat(3,1) = ax(1)*ax(3)*(1-cos(theta))    + ax(2)*sin(theta);
            rotMat(3,2) = ax(2)*ax(3)*(1-cos(theta))    - ax(1)*sin(theta);
            rotMat(3,3) = ax(3)*ax(3)*(1-cos(theta))    + cos(theta);
            xn = x * rotMat;
        end

        function verts_out = offsetXYZ (verts, x)
            % translate the position vertices
            
            % this statement uses implicit broadcasting
            verts_out = verts + x;
            
        end
        
        function v = lagrangeInterp (x,y,u)
            
            n = length(x);
            v = zeros(size(u));
            
            for k = 1:n
                w = ones(size(u));
                for j = [1:k-1 k+1:n]
                    w = (u-x(j))./(x(k)-x(j)).*w;
                end
                v = v + w*y(k);
            end
            
        end
        
        function v = linearInterp (x1, x2, y1, y2, u)
            % linearInterp simple linear interpolation with no input checking
            %
            % Syntax
            %
            % v = wsim.hydroBody.linearInterp (x1, x2, y1, y2, u)
            %
            % Description
            %
            % wsim.hydroBody.linearInterp returns a simple linear
            % interpolation with extrapolation without any input checking
            % for speed. A linear function is created from two input data
            % points on the line, (x1,y1) and (x2,y2).
            %
            % Input
            %
            %  x1 - x coordinate of first data point on line
            %
            %  x2 - x coordinate of second data point on line
            %
            %  y1 - y coordinate of first data point on line
            %
            %  y2 - y coordinate of second data point on line
            %
            %  u - x coordinate(s) at which to perform the interpolation
            %
            % Output
            %
            %  v - value of linear finction at interpolation points in u.
            %
            %
            %
            % See also: wsim.hydroBody.lagrangeInterp
            %
            %
            
            m = (y2 - y1) ./ (x2 - x1);
            c = y1 - m.*x1;
            
            v = m.*u + c;
            
        end

        
        function o = vcross (v1, v2)
            % Vector cross product for multiple 3 element vectors
            %
            % Syntax
            %
            % o = wsim.hydroBody.vcross (v1, v2)
            %
            % Description
            %
            % 
            %
            % Input
            % 
            %  v1 - (3 x n) matrix where the rows are each 3 element
            %   vectors
            %
            %  v2 - (3 x n) matrix where the rows are each 3 element
            %   vectors
            %
            % Output
            %
            %  o - (3 x n) matrix where each column is the cross product of
            %    the vectors in each row of v1 and v2
            %

            o = [ v1(2,:).*v2(3,:) - v1(3,:).*v2(2,:);
                  v1(3,:).*v2(1,:) - v1(1,:).*v2(3,:);
                  v1(1,:).*v2(2,:) - v1(2,:).*v2(1,:) ];
        end
        
        function [hax, hfig] = formatBEMOutputPlot (heading, subtitle, x_lables, y_lables, X_data, Y_data, data_names, notes, varargin)
            
            options.Axes = [];
            options.Figure = [];
            
            options = parse_pv_pairs (options, varargin);
            
            if isempty (options.Figure)
                hfig = figure ('Position', [50,500,975,521]);
%                 old_units = 
%                 set (hfig, 'PaperUnits', get (hfig, 'Units'));
%                 set
                set (hfig, 'PaperPositionMode', 'auto');
            else
                hfig = options.Figure;
            end
            
            if isempty (options.Axes)
                
                hax(1) = axes ('Parent', hfig, 'Position', [0.0731 0.3645 0.2521 0.4720]);
                box (hax(1), 'on');
                title (subtitle(1));
                xlabel (x_lables(1), 'Interpreter', 'latex');
                ylabel (y_lables(1), 'Interpreter', 'latex');
            
                hax(2) = axes ('Parent', hfig, 'Position', [0.3983 0.3645 0.2521 0.4720]);
                box (hax(2), 'on');
                title (subtitle(2));
                xlabel (x_lables(2), 'Interpreter', 'latex');
                ylabel (y_lables(2), 'Interpreter', 'latex');

                hax(3) = axes ('Parent', hfig, 'Position', [0.7235 0.3645 0.2521 0.4720]);
                box (hax(3), 'on');
                title (subtitle(3));
                xlabel (x_lables(3), 'Interpreter', 'latex');
                ylabel (y_lables(3), 'Interpreter', 'latex');
                            

                annotation (hfig,'textbox',[0.0 0.9 1.0 0.1],...
                    'String', heading,...
                    'Interpreter', 'latex',...
                    'HorizontalAlignment', 'center',...
                    'FitBoxToText', 'off',...
                    'FontWeight', 'bold',...
                    'FontSize', 12,...
                    'EdgeColor', 'none');

                annotation (hfig,'textbox',[0.0 0.0 1.0 0.2628],...
                    'String', notes,...
                    'Interpreter', 'latex',...
                    'FitBoxToText', 'off',...
                    'EdgeColor', 'none');

            else
                assert (numel (options.Axes) == 3, 'options.Axes should be a three element vector');
                for ind = 1:numel (options.Axes)
                    assert (mbdyn.pre.base.isAxesHandle (options.Axes(ind)), 'options.Axes must be a vector of axes handles');
                end
                hax = options.Axes;
            end

            hold (hax(1), 'on');
            hold (hax(2), 'on');
            hold (hax(3), 'on');

%             [p,b,s] = size(Y_data);
            
            for i = 1:size (Y_data, 2)
                
                plot (X_data, squeeze (Y_data(1,i,:)), 'LineWidth', 1, 'Parent', hax(1), 'DisplayName', data_names{1,i});
                plot (X_data, squeeze (Y_data(2,i,:)), 'LineWidth', 1, 'Parent', hax(2), 'DisplayName', data_names{2,i});
                plot (X_data, squeeze (Y_data(3,i,:)), 'LineWidth', 1, 'Parent', hax(3), 'DisplayName', data_names{3,i});
                
            end
            
            if isempty (options.Axes)
                
                legend (hax(1), 'location', 'best', 'Box', 'off', 'Interpreter', 'none');
                legend (hax(2), 'location', 'best', 'Box', 'off', 'Interpreter', 'none');
                legend (hax(3), 'location', 'best', 'Box', 'off', 'Interpreter', 'none');
            
            end

        end
        
    end
    
    
    % getters and setters
    methods
        
        function set.mass (self, new_mass)
            
            if ischar (new_mass)
                ok = check.allowedStringInputs (new_mass, {'equilibrium', 'fixed'}, false);
                assert (ok, 'If mass is a string, it must be ''equilibrium'' or ''fixed''');
            else
                check.isNumericScalar(new_mass, true, 'mass', 0);
%                 assert (new_mass > 0, 'mass must be greater than 0');
            end
            
            self.mass = new_mass;
            
        end
        
        
        function set.momOfInertia (self, new_momOfInertia)
            
            ok = check.isNumericMatrix (new_momOfInertia, false, 'new_momOfInertia', 1);
            
            assert (ok && (numel (new_momOfInertia) == 3), ...
                'momOfInertia must be a 3 element vector of positive real values. This is the diagonal of the inertia matrix ([Ixx, Iyy, Izz])' );
            
            self.momOfInertia = new_momOfInertia;
            
        end
        
        function set.dispVol (self, new_dispVol)
            
            check.isNumericScalar (new_dispVol, true, 'dispVol', 1);
            
            self.dispVol = new_dispVol;
            
        end
        
        
    end

end
