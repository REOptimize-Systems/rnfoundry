function varargout = prescribedmotode_activerect_ROTARY (t, x, design, simoptions)
% solves the right had side of the differential
% equations for a machine moving with a prescribed motion
%
% Syntax:
%
% Input
%
% x is a vector of values of the state of the sytem at time t. The members
% of x are the following:
%
%
% design is a standard machine design structure popluated with all the
% necessary information to perform the simulation. 
%
% 'simoptions'  is a structure determining the buoy and sea parameters used
% in the simulation, and also any penalties to be used in the scoring of
% the design. Essential fields are:

    if nargin == 0
        % get the output names
        varargout{1} = { 'ydot', 'dpsidthetaR', 'EMF', 'thetaT', 'omegaT', ...
                         'Tqpto', 'RPhase', 'Vabc', ...
                         'Vabc_conv', 'D', 'Idq', 'Vsref', 'PI_vals' };
        return;
    end

    % Change the x members into more useful variables names, MATLAB will
    % optimise away any memory penalty associated with this I think    
    Iphases = x(simoptions.ODESim.SolutionComponents.PhaseCurrents.SolutionIndices);
    
    Icoils = Iphases ./ design.Branches;

    % Initialize dx with zeros
    dx = zeros (size (x));
    
    % get the velocity and position at the current time
    [thetaE, omegaE] = prescribedmotomegatheta (t, simoptions);

    % determine the machine outputs
    % Get the EMF and torques using the core machine simulation function
    [Tqeff, ~, EMF, dpsidthetaR, design] = ...
        machineodesim_AM (design, simoptions, thetaE, 0, omegaE, 0, Icoils);
    
    theta_flux = thetaE .* design.Poles / 2 + pi();
%     theta_flux = thetaE .* design.Poles / 2 + pi()/2;
    Idq = abc2dq0 (Iphases(:), theta_flux, true);
%     theta_flux = thetaE .* design.Poles / 2;
%     Idq = abc2dq0 (Iphases(:), theta_flux, true);

    Vo = design.MachineSidePowerConverter.Vdc;
    
    if t <= simoptions.FOCTApp
        Vsdref = 0;
        Vsqref = 0;
        Vabc = zeros (size (Iphases));
        Vabc_conv = Vabc;
        D = zeros (numel (Iphases), 1);
    else
        
        dt = calcDt (design.FOControl.PI_d, t);
        Vsdref = calculate ( design.FOControl.PI_d, Idq(1), simoptions.Isdref, dt );
        Vsqref = calculate ( design.FOControl.PI_q, Idq(2), simoptions.Isqref, dt );
        
        % decouple the d and q axes outputs
        omega_flux = omegaE .* design.Poles / 2;
        Vsdref = Vsdref + ( -omega_flux * design.FOControl.Ls * Idq(2) );
        Vsqref = Vsqref + ( omega_flux * design.FluxLinkagePhasePeak );
        
        Vabc = dq02abc ( [Vsdref; Vsqref], theta_flux, true );
%         Vabc = dq02abc ( [Vsdref; Vsqref], theta_flux, false );
        
        Vabc_conv = -Vabc;
%         Vabc_conv = Vabc;
        
        if any (abs(Vabc_conv) > Vo)
            
            scalefac = Vo / max(abs(Vabc_conv));
        
            Vabc_conv = Vabc_conv * scalefac;
            
        end
        
        D =  Vabc_conv ./ Vo;
        
    end
    
    VnN = 0;
    
    % find the derivatives of the phase currents (solving the differential
    % equation describing the power converter circuit)
    dx(1:design.Phases,1) = activerectifiercurrentderiv ( Iphases(:), ...
                                                          EMF(:), ...
                                                          design.MachineSidePowerConverter.REquivalent, ...
                                                          design.L, ...
                                                          D, ...
                                                          Vo, ...
                                                          VnN );
     
    
    % ************************************************************************

    % Now assign the outputs
    varargout{1} = dx;

    % To record the forces
    if nargout > 1
        
        % rate of change of flux linkage with displacement 
        varargout{2} = dpsidthetaR;
        % per-coil induced voltage 
        varargout{3} = EMF;
        % vertical displacement of the translator  
        varargout{4} = thetaE;
        % vertical velocity of the translator
        varargout{5} = omegaE;
        % total electromagnetic forces acting on effector
        varargout{6} = Tqeff;
        % output the phase resistance at each time step
        varargout{7} = diag(design.RPhase)';
        
        varargout{8} = Vabc;
        varargout{9} = Vabc_conv;
        varargout{10} = D;
        varargout{11} = Idq;
        varargout{12} = [Vsdref, Vsqref];
        varargout{13} = [design.FOControl.PI_d.error, design.FOControl.PI_q.error, design.FOControl.PI_d.integral, design.FOControl.PI_q.integral ];
        
    end

end

