function [design, simoptions] = finfun_ACTIAM(design, simoptions)
    
    design = ratios2dimensions_ACTIAM(design);

    design = makelossfcns_ACTIAM(design);
    
    [design, simoptions] = finfun_TM(design, simoptions);
    
end

function design = makelossfcns_ACTIAM(design)

    % calculate the losses in a single pole region of the field and
    % armature back iron. Note here that the Bx and By values have been
    % swapped, as in the FEA sim the 
    [histloss, eddyloss, excessloss] = ...
        softferrolossrectregionpartcalc( design.CoreLoss.Bx, ...
                                         design.CoreLoss.By, ...
                                         design.CoreLoss.Bz, ...
                                         design.CoreLoss.kc, ...
                                         design.CoreLoss.kh, ...
                                         design.CoreLoss.ke, ...
                                         design.CoreLoss.beta, ...
                                         design.CoreLoss.dx, ...
                                         design.CoreLoss.dy, ...
                                         design.CoreLoss.dz );                              
                                 
                                 
    % make constant core loss slms which evaluate to the calculated values
    % at all positions (as the core is featureless and the losses are
    % always the same at a given velocity), this for compatibility with
    % lossforces_AM.m
    design.CoreLossSLMs.hxslm = slmengine([0,2], [histloss, histloss], ...
                                'knots', 2, 'Degree', 0, 'EndCon', 'Periodic');
                            
    design.CoreLossSLMs.cxslm = slmengine([0,2], [eddyloss, eddyloss], ...
                                'knots', 2, 'Degree', 0, 'EndCon', 'Periodic');
                            
    design.CoreLossSLMs.exslm = slmengine([0,2], [excessloss, excessloss], ...
                                'knots', 2, 'Degree', 0, 'EndCon', 'Periodic');
                            
    % generate positions for the flux density integral data
    design.intBdata.pos = linspace(0, 2, 20);
    
    % now extract the information necessary to create the squared
    % derivative data for the coil eddy current calculation
%     design.intBdata.intB1 = intBfrm2dBpoly(design.Ri, ...
%                                           -design.Wc/(2*design.Wp), ...
%                                           design.Hc, ...
%                                           design.Wc/design.Wp, ...
%                                           [zeros(numel(design.intBdata.pos), 1), (design.intBdata.pos)'], ...
%                                           [design.p_Bx, design.p_By], ...
%                                           false, ...
%                                           design.Wp);

    design.intBdata.intB1 = intBfrm2dBgrid(design.Ri, ...
                                          -design.Wc/(2*design.Wp), ...
                                          design.Hc-design.FEMMTol-2*max(eps(design.X(:))), ...
                                          design.Wc/design.Wp, ...
                                          [zeros(numel(design.intBdata.pos), 1), (design.intBdata.pos)'], ...
                                          design.X, design.Y, cat(3, design.Bx, design.By), ...
                                          false, ...
                                          design.Wp);

    % generate the slm containing the part calculated SVD for eddy current
    % calculation in lossforces_AM.m
    design.slm_eddysfdpart = makesfdeddyslm(design.WireResistivityBase, ...
                                            design.MTL, ...
                                            design.Dc, ...
                                            design.CoilTurns, ...
                                            design.intBdata.pos .* design.Wp, ...
                                            design.intBdata.intB1 ./ design.CoilArea, ...
                                            [], ...
                                            design.NStrands);  
    
end

