function [dx, bouyancy_force, excitation_force_heave, ...
    excitation_force_surge, radiation_force_heave, ...
    radiation_force_surge, FBDh, FBDs, wave_height] = buoyodesim(t, x, dx, xBh, vBh, vBs, simoptions, Fexternal)
% buoyodesim: solves the rhs of the system of differential equations
% decribing the forces acting on a heaving buoy, and also determines the
% excitation, radiation, and buoyancy forces acting on the buoy.
%
%     
    
    % Get the solution indices for the hydrodynamic variables
    buoyinds = [ simoptions.ODESim.SolutionComponents.BuoyRadiationHeave.SolutionIndices, ...
                 simoptions.ODESim.SolutionComponents.BuoyRadiationSurge.SolutionIndices ];
    
    % calculate the forces acting on the buoy
    [ buoyforcedx, ...
      bouyancy_force, ...
      excitation_force_heave, ...
      excitation_force_surge, ...
      radiation_force_heave, ...
      radiation_force_surge, ...
      FBDh, ...
      FBDs, ...
      wave_height]  = buoyodeforces (t, x(buoyinds), xBh, vBh, vBs, simoptions);

    % copy the force derivatives to the derivatives vector at the
    % appropriae point
    dx(buoyinds,:) = buoyforcedx;
    
    % Buoy acceleration in heave
    heavevelind = simoptions.ODESim.SolutionComponents.BuoyVelocityHeave.SolutionIndices;

    dx(heavevelind,1) = real ( (excitation_force_heave + ...
                      radiation_force_heave + ...
                      bouyancy_force + ...
                      FBDh + ...
                      Fexternal(1)) / (simoptions.BuoyParameters.mass_external + ...
                                       simoptions.BuoyParameters.HM_infinity) ...
                             );

	dx(heavevelind,1) = dx(heavevelind,1) * simoptions.SeaParameters.ConstrainHeave;
    
    % Buoy acceleration in surge
    surgevelind = simoptions.ODESim.SolutionComponents.BuoyVelocitySurge.SolutionIndices;

    dx(surgevelind,1) = real ( (excitation_force_surge + ...
                    radiation_force_surge + ...
                    FBDs + ...
                    Fexternal(2)) / (simoptions.BuoyParameters.mass_external + ...
                                     simoptions.BuoyParameters.SM_infinity) ...
                             );
                                 
	dx(surgevelind,1) = dx(surgevelind,1) * simoptions.SeaParameters.ConstrainSurge;
       
end