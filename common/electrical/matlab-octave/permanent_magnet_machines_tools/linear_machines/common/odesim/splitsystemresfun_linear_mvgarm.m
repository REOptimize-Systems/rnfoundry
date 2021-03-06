function [results, design] = splitsystemresfun_linear_mvgarm(T, Y, design, simoptions, results)
% completes the processing of data generated by
% splitodesystemres_linear_mvgarm.m during an ODE simulation of an
% electrical machine with a moving armature (and field) using odesplit
%
% Syntax
%
% [results, design] = splitsystemresfun_linear_mvgarm(T, Y, design, simoptions, results)
%
        
    design.minLongMemberLength = 2 * max(results.peakxT - results.troughxA, ...
        results.peakxA - results.troughxT) + (max(design.Poles) * design.PoleWidth);
    
    design.minLongMemberPoles = ceil(design.minLongMemberLength ./ design.PoleWidth);

    design.minLongMemberLength = design.minLongMemberPoles * design.PoleWidth;

    design.extraFptoMass = 1.1 * results.MaxFpto / simoptions.BuoySim.BuoyParameters.g;

    design.vRmax = results.vRmax;
%     design.xArms = rms(interp1(T, Y(:,5), 0:max(T)/(length(T)*2):max(T)));
    
    % do common results (mostly electrical/power calcs)
    [results, design] = splitsystemresfun_AM(T, Y, design, simoptions, results);

end