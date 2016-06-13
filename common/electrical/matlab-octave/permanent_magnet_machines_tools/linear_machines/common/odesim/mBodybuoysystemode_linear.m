function varargout = mBodybuoysystemode_linear (t, x, design, simoptions)
% systemodeforcefcn_linear: solves the right had side of the differential
% equations for the combined snapper and buoy system
%
% Syntax:
%
% [dx] = systemode_linear(t, x, design, simoptions)
% 
% [..., FBDh] = ] = systemode_linear(t, x, design, simoptions)
%     
% [..., bouyancy_force] = systemode_linear(t, x, design, simoptions)
% 
% [..., excitation_force_heave] = systemode_linear(t, x, design, simoptions)
% 
% [..., excitation_force_surge] = systemode_linear(t, x, design, simoptions)
% 
% [..., Hrad_force] = systemode_linear(t, x, design, simoptions)
% 
% [..., Srad_force] = systemode_linear(t, x, design, simoptions)
% 
% [..., dpsidxR] = systemode_linear(t, x, design, simoptions)
% 
% [..., EMF] = systemode_linear(t, x, design, simoptions)
% 
% [..., Ffea] = systemode_linear(t, x, design, simoptions)
% 
% [..., Fs] = systemode_linear(t, x, design, simoptions)
% 
% [..., Ffea_surge] = systemode_linear(t, x, design, simoptions)
%
% Input
%
% x is a vector of values of the state of the sytem at time t. The members
% of x are the following:
%
% x(1) = Buoy position - heave xBh
% x(2) = Bouy velocity - heave vBh
% x(3) = Bouy position - surge xBs
% x(4) = Buoy velocity - surge vBs
% x(5) = I, coil current in phase 1
% x(6) = I, coil current in phase 2
% x(7) = I, coil current in phase 3
% x(8) = I(1) (heave)
% x(9) -- x(N) = I(2) - I(N-6) (heave)
% x(N+1) -- x(N+M) = I(1) - I(M) (surge)
%
% design is a standard machine design structure popluated with all the
% necessary information to perform the simulation. 
%
% 'simoptions'  is a structure determining the buoy and sea parameters used
% in the simulation, and also any penalties to be used in the scoring of
% the design. Essential fields are:
%
%	- BuoyParameters - 
%
%   a structure containing relevent detailsabout the characteristics of the
%   buoy such as radius, draft etc. See defaultbuoyparameters for details. 
%   It should contain the following members:
%
%   Halpha - alpha coeficients in heave
%   Hbeta - beta coefficients in heave
%   Salpha - alpha coeficients in surge
%   Sbeta - beta coeficients in surge
%   drag_coefficient - coefficient of drag on the buoy
%   a - radius of the buoy
%   g - local gravitational constant (in case we deploy on Mars or Moon in 
%       future)
%   rho - density of seawater (see above)
%
%	- SeaParameters - 
%
%   optional structure containing relevent details of the sea to be used in
%   the simulation. If not supplied the structure returned by the function
%   defaultseaparameters will be used. See defaultseaparameters for further
%   details. It should contain the following members:
%
%   amp - vector of wave amplitudes for each wave sinusoid being applied
%   phase - vector of phase values for each sinusoid being applied
%   sigma - vector of angular frequencies for each sinusoid
%   wave_number -  vector of wave numbers for the frequencies
%   tether_length - the length of the tether from the buoy to the hawse
%                   hole
%
% Output:
%
%   dx - solution to the rhs of differential equations describing the
%   system at the current time step
%
%   EMF - per-coil induced voltage at the current time step
%
%   Ffea - total electromagnetic forces acting on armature at the current
%   time step
%
%   xT - vertical displacement of the translator at the current time step
%
%   vT - vertical velocity of the translator at the current time step
%
%   Ffeah - heave component of generator forces on buoy at the current time
%   step
%
%   Ffeas - surge component of generator forces on buoy at the current time
%   step
%
%   FBDh - buoy drag forces in heave at the current time step
%
%   FBDs - buoy drag forces in surge at the current time step
%
%   bouyancy_force - simple buoyancy force at the current time step
%
%   excitation_force_heave - excitation force in heave at the current time
%   step
%
%   excitation_force_surge - excitation force in surge at the current time
%   step
%
%   radiation_force_heave - radiation force in heave at the current time
%   step
%
%   radiation_force_surge - radiation force in surge at the current time
%   step
%
%   dlambdaVdxR -rate of change of flux linkage with relative displacement
%   at the current time step
%

    if nargin == 0

        % get the output names
        varargout{1} = {'ydot', 'EMF', 'Feff', 'xE', 'vE', ...
                        'Ffea_heave', 'Ffea_surge', 'FBDh', 'FBDs', ...
                        'buoyancy_force', 'excitation_force_heave', ...
                        'excitation_force_surge', 'radiation_force_heave', ...
                        'radiation_force_surge', 'FaddB', 'dpsidxR', ...
                        'wave_height', 'FaddEBD', 'RPhase'};
        return;
    end
    
    % get the multibody system 
    mb = design.MultiBodySystem;
%     % update it's state, this will allow us to use buoy.vel etc. to the
%     % velocities and positions
%     overwriteState (mb, t, x(simoptions.ODESim.SolutionComponents.MultiBodySystem.SolutionIndices));
    % get the buoy
    buoy = simoptions.ODESim.SolutionComponents.MultiBodySystem.Buoy;
    
    mbsolutioninds = simoptions.ODESim.SolutionComponents.MultiBodySystem.SolutionIndices;
    
    % Change the x members into more useful variables names, MATLAB will
    % optimise away any memory penalty associated with this I think
    xBh = x(mbsolutioninds(simoptions.ODESim.SolutionComponents.MultiBodySystem.BuoyPositionSolutionInd),:) ...
            - buoy.sz/2 + simoptions.BuoyParameters.draft; % x(simoptions.ODESim.SolutionComponents.BuoyPositionHeave.SolutionIndices);
    vBh = x(mbsolutioninds(simoptions.ODESim.SolutionComponents.MultiBodySystem.BuoyVelocitySolutionInd),:); % x(simoptions.ODESim.SolutionComponents.BuoyVelocityHeave.SolutionIndices);
%     xBh = buoy.pos(3) - buoy.sz/2 + simoptions.BuoyParameters.draft;
%     vBh = buoy.vel(3);
    xBs = 0; % x(simoptions.ODESim.SolutionComponents.BuoyPositionSurge.SolutionIndices);
    vBs = 0; % x(simoptions.ODESim.SolutionComponents.BuoyVelocitySurge.SolutionIndices);
    Iphases = x(simoptions.ODESim.SolutionComponents.PhaseCurrents.SolutionIndices);
    
    Icoils = Iphases ./ design.Branches;

    % Initialize dx with zeros
    dx = zeros(size(x));
    
    % determine the machine outputs
    [dpsidxR, EMF, Feff, FfeaVec, xE, vE, unitv, design] = ...
        machineodesim_linear(design, simoptions, Icoils, xBh, vBh, xBs, vBs);

    % find the derivative of the coil current (solving the differential
    % equation describing the simple output circuit)
    dx(simoptions.ODESim.SolutionComponents.PhaseCurrents.SolutionIndices,1) = ...
        circuitode_linear (Iphases, EMF, design);

    % Calculate the drag forces on the translator
    % Fdrag = sign(vT) .* 0.5 .* realpow(vT,2) .* simoptions.BuoyParameters.rho .* design.Cd .* design.DragArea;
%     [FaddB, ForceEBD] = feval ( simoptions.forcefcn, design, simoptions, ...
%                                  xE, vE, EMF, Iphases, xBh, vBh, xBs, vBs, ...
%                                  simoptions.ODESim.ForceFcnArgs{:} );
    
    % ********************************************************************
    % Buoy Acceleration, these calcs assume all of the mass is in the buoy,
    % this should be a reasonable assumption provided the mass of the
    % translator is not too significant in comparison

%     Fexternal = FfeaVec + FaddB;
    
    % Determine the buoy/sea interaction forces and derivatives
    % Get the solution indices for the hydrodynamic variables
%     buoyinds = [ simoptions.ODESim.SolutionComponents.BuoyRadiationHeave.SolutionIndices, ...
%                  simoptions.ODESim.SolutionComponents.BuoyRadiationSurge.SolutionIndices ];
    
    % calculate the forces acting on the buoy
%     [ buoyforcedx, ...
%       buoyancy_force, ...
%       excitation_force_heave, ...
%       excitation_force_surge, ...
%       radiation_force_heave, ...
%       radiation_force_surge, ...
%       FBDh, ...
%       FBDs, ...
%       wave_height] = buoyodeforces (t, x(buoyinds), xBh, vBh, vBs, simoptions);

      buoyforcedx = 0;
      buoyancy_force = 0;
      excitation_force_heave = 0;
      excitation_force_surge = 0;
      radiation_force_heave = 0;
      radiation_force_surge = 0;
      FBDh = 0;
      FBDs = 0;
      FaddB = 0;
      ForceEBD = [0, 0, 0, 0, 0, 0, 0];
      wave_height = 0;

    % copy the force derivatives to the derivatives vector at the
    % appropriae point
%     dx(buoyinds,:) = buoyforcedx;

    % ************************************************************************

    % set the forces in the multibody system
    % buoy forces
%     simoptions.ODESim.SolutionComponents.MultiBodySystem.Buoy.data = ...
%         [0; 0; buoyancy_force+excitation_force_heave+radiation_force_heave+FBDh+Feff];
%     simoptions.ODESim.SolutionComponents.MultiBodySystem.Buoy.data = buoyancy_force;

    % advance the multibody system
    
    dx(simoptions.ODESim.SolutionComponents.MultiBodySystem.SolutionIndices) ...
         = eom ( mb, ...
                 t, ...
                 x(simoptions.ODESim.SolutionComponents.MultiBodySystem.SolutionIndices), ...
                 simoptions.MultiBodySystem.tidy );
    
    % Now assign the outputs
    varargout{1} = dx;

    % To record the forces
    if nargout > 1
        
        % per-coil induced voltage 
        varargout{2} = EMF;
        % total power take-off force acting on effector (
        varargout{3} = Feff;
        % vertical displacement of the effector  
        varargout{4} = xE;
        % vertical velocity of the effector
        varargout{5} = vE;
        % heave component of generator forces
        varargout{6} = FfeaVec(1);
        % surge component of generator forces
        varargout{7} = FfeaVec(2);
        % buoy drag forces in heave
        varargout{8} = FBDh;
        % buoy drag forces in surge
        varargout{9} = FBDs;
        % simple buoyancy force
        varargout{10} = buoyancy_force;
        % excitation force in heave
        varargout{11} = excitation_force_heave;
        % excitation force in surge
        varargout{12} = excitation_force_surge;
        % radiation force in heave
        varargout{13} = radiation_force_heave;
        % radiation force in surge
        varargout{14} = radiation_force_surge;
        % Additional forces on buoy
        varargout{15} = FaddB;
        % rate of change of flux linkage with displacement 
        varargout{16} = dpsidxR;
        % wave height
        varargout{17} = wave_height;
        % breakdown of forces on effector
        varargout{18} = ForceEBD;
        % Phase resistance
        varargout{19} = diag(design.RPhase);
        
    end

end

