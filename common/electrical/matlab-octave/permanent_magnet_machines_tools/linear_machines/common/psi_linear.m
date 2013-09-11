function lambda = psi_linear(design, y)
% psi_linear: finds the flux linkage in a coil given a 2D polynomial fitted
% to the vector potential, or 2D grid of data

    y = reshape(y, [], 1);

    if isfield(design, 'Apoly') && ~isfield(design, 'Agrid')
        usepoly = true;
    elseif ~isfield(design, 'Apoly') && isfield(design, 'Agrid')
        usepoly = false;
    elseif ~any(isfield(design, {'Apoly', 'Agrid'}))
        
        error('PSI_LINEAR:badpsimode', ...
            'No Apoly or Agrid field supplied')
        
    elseif all(isfield(design, {'Apoly', 'Agrid'}))
        
        if isfield(design, 'PsiMode')
            
            switch design.PsiMode
                
                case 'poly'
                    usepoly = true;
                case 'gridfit'
                    usepoly = false;
                otherwise
                    
                    error('PSI_LINEAR:badpsimode', ...
                        'Unrecognised PsiMode value, expected ''poly'', or ''gridfit'', got: %s', design.PsiMode)
                    
            end
        else
            usepoly = true;
        end
        
    end
    
    
    if usepoly
        
        if design.CoilLayers == 2

            lambda = fluxlinkagefrm2dApoly(-design.Hc/2, ...
                                       0.5 - (design.WcVTaup / 2), ...
                                       0, ...
                                       1.5 - (design.WcVTaup / 2), ...
                                       design.Hc/2, ...
                                       design.WcVTaup, ...
                                       [zeros(size(y)), y], ...
                                       design.APoly, ...
                                       design.CoilTurns, ...
                                       design.ls, ...
                                       1);

        else

            lambda = fluxlinkagefrm2dApoly(-design.Hc/2, ...
                                       0.5 - (design.WcVTaup / 2), ...
                                       -design.Hc/2, ...
                                       1.5 - (design.WcVTaup / 2), ...
                                       design.Hc, ...
                                       design.WcVTaup, ...
                                       [zeros(size(y)), y], ...
                                       design.APoly, ...
                                       design.CoilTurns, ...
                                       design.ls, ...
                                       1);
        end
    else
        
        if design.CoilLayers == 2

            lambda = fluxlinkagefrm2dAgrid(-design.Hc/2, ...
                                       0.5 - (design.WcVTaup / 2), ...
                                       0, ...
                                       1.5 - (design.WcVTaup / 2), ...
                                       design.Hc/2, ...
                                       design.WcVTaup, ...
                                       [zeros(size(y)), y], ...
                                       design.X, design.Y, design.Agrid, ...
                                       design.CoilTurns, ...
                                       design.ls);

        else

            lambda = fluxlinkagefrm2dAgrid(-design.Hc/2, ...
                                       0.5 - (design.WcVTaup / 2), ...
                                       -design.Hc/2, ...
                                       1.5 - (design.WcVTaup / 2), ...
                                       design.Hc, ...
                                       design.WcVTaup, ...
                                       [zeros(size(y)), y], ...
                                       design.X, design.Y, design.Agrid, ...
                                       design.CoilTurns, ...
                                       design.ls);
        end        
        
    end
    
    
    
end