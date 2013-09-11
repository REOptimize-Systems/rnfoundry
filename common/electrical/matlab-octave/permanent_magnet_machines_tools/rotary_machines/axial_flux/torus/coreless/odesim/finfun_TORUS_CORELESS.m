function [design, simoptions] = finfun_TORUS_CORELESS(design, simoptions)
% post-processes the data produced by simfun_TORUS_CORELESS in readiness
% for a dynamic simulation

    % do post-processing specific to coreless torus machine
    
    design.Rmm = (design.Rmo + design.Rmi) / 2;
    theta = design.tauci / design.Rmm;
    design.taucio = theta * (design.Rco - design.Wc/2);
    design.taucii = theta * (design.Rci + design.Wc/2);
    
    design.MTL = isotrapzcoilmtl(design.taucio, ...
                                 design.taucii, ...
                                 design.Rmo - design.Rmi, ...
                                 design.Wc);
                             
    design.CoilResistance = design.WireResistivityBase * ...
                            design.MTL * ...
                            design.CoilTurns ./ (pi * (design.Dc/2)^2);
                        
    % generate the flux linkage data from the vector potential polynomial
    % at a number of coil positions
    design.psilookup = linspace(0, 1, 10);
    
    % generate positions for the flux density integral data
    design.intBdata.pos = linspace(0, 2, 20);
    
    if design.CoilLayers == 1

        % extract the flux linkage for the coils from the position of minimum
        % flux linkage to maximum flux linkage. The scale factor is one as the
        % coil height, and therefore area are already scaled to the pole pitch
        design.psilookup(2,:) = ...
            fluxlinkagefrm2dAgrid(-(design.outermagsep/2) + design.g, ...
                                  -design.tauco/(2*design.taupm), ...
                                  -(design.outermagsep/2) + design.g, ...
                                   design.tauci/(2*design.taupm), ...
                                   design.tc, ...
                                   (design.tauco - design.tauci)/(2*design.taupm), ...
                                   [zeros(numel(design.psilookup(1,:)), 1), (design.psilookup(1,:)+1.5)'], ...
                                   design.X, design.Y, design.A, ...
                                   design.CoilTurns, ...
                                   design.Rmo - design.Rmi);
                               
        
        % now extract the information necessary to create the squared
        % derivative data for the coil eddy current calculation
        design.intBdata.intB1 = intBfrm2dBgrid(-(design.outermagsep/2) + design.g, ...
                                              -design.tauco/(2*design.taupm), ...
                                              design.tc, ...
                                              (design.tauco - design.tauci)/(2*design.taupm), ...
                                              [zeros(numel(design.intBdata.pos), 1), (design.intBdata.pos+1.5)'], ...
                                              design.X, design.Y, cat(3, design.Bx, design.By), ...
                                              false, ...
                                              design.taupm);
                           
        design.intBdata.intB2 = intBfrm2dBgrid(-(design.outermagsep/2) + design.g, ...
                                               design.tauci/(2*design.taupm), ...
                                               design.tc, ...
                                               (design.tauco - design.tauci)/(2*design.taupm), ...
                                               [zeros(numel(design.intBdata.pos), 1), (design.intBdata.pos+1.5)'], ...
                                               design.X, design.Y, cat(3, design.Bx, design.By), ...
                                               false, ...
                                               design.taupm);                           
        
    elseif design.CoilLayers == 2
        
        % extract the flux linkage for the coils from the position of minimum
        % flux linkage to maximum flux linkage. The scale factor is one as the
        % coil height, and therefore area are already scaled to the pole pitch
        design.psilookup(2,:) = ...
            fluxlinkagefrm2dAgrid(-(design.outermagsep/2) + design.g, ...
                                  -design.tauco/(2*design.taupm), ...
                                  -(design.outermagsep/2) + design.g + design.tc/2, ...
                                   design.tauci/(2*design.taupm), ...
                                   design.tc/2, ...
                                   (design.tauco - design.tauci)/(2*design.taupm), ...
                                   [zeros(numel(design.psilookup(1,:)), 1), (design.psilookup(1,:)+1.5)'], ...
                                   design.X, design.Y, design.A, ...
                                   design.CoilTurns, ...
                                   design.Rmo - design.Rmi);
         
        % now extract the information necessary to create the squared
        % derivative data for the coil eddy current calculation
        design.intBdata.intB1 = intBfrm2dBgrid(-(design.outermagsep/2) + design.g, ...
                                               -design.tauco/(2*design.taupm), ...
                                               design.tc/2, ...
                                               (design.tauco - design.tauci)/(2*design.taupm), ...
                                               [zeros(numel(design.intBdata.pos), 1), (design.intBdata.pos+1.5)'], ...
                                               design.X, design.Y, cat(3, design.Bx, design.By), ...
                                               false, ...
                                               design.taupm);
                           
        design.intBdata.intB2 = intBfrm2dBgrid(-(design.outermagsep/2) + design.g+ design.tc/2, ...
                                               design.tauci/(2*design.taupm), ...
                                               design.tc/2, ...
                                               (design.tauco - design.tauci)/(2*design.taupm), ...
                                               [zeros(numel(design.intBdata.pos), 1), (design.intBdata.pos+1.5)'], ...
                                               design.X, design.Y, cat(3, design.Bx, design.By), ...
                                               false, ...
                                               design.taupm); 
                           
    end
                           
	% if not supplied work out the displacement of set of coils
    % representing a full set of adjacent phases
    if ~isfield(design, 'taupcg')
        design.taupcg = design.phases * design.tauco;
    end
    
    % calculate the separation between adjacent coils in the phases
    design.CoilPositions = coilpos(design.phases) * design.taupcg / design.taupm;
    
    % make the loss functions for lossforces_AM.m
    design = makelossfcns_TORUS_CORELESS(design);
    
    % call finfun_TORUS
    [design, simoptions] = finfun_TORUS(design, simoptions);

end 


function design = makelossfcns_TORUS_CORELESS(design)

    % generate the slm containing the part calculated SVD for eddy current
    % calculation in lossforces_AM.m
    design.slm_eddysfdpart = makesfdeddyslm(design.WireResistivityBase, ...
                                            design.Rmo - design.Rmi, ...
                                            design.Dc, ...
                                            design.CoilTurns, ...
                                            design.intBdata.pos .* design.taupm, ...
                                            design.intBdata.intB1 ./ design.CoilArea, ...
                                            design.intBdata.intB2 ./ design.CoilArea, ...
                                            design.NStrands); 
                         
    % make constant core loss slms which evaluate to zero (as there is no
    % core), this for compatibility with lossforces_AM.m
    design.CoreLossSLMs.hxslm = slmengine([0,2], [0,0], 'knots', 2, 'Degree', 0, 'EndCon', 'Periodic');
    design.CoreLossSLMs.cxslm = design.CoreLossSLMs.hxslm;
    design.CoreLossSLMs.exslm = design.CoreLossSLMs.hxslm; 
    
end