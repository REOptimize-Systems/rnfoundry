function [score, design, simoptions] = systempenalties_ROTARY(design, simoptions, score)
% adds penalties related to the operation of a rotary generator system not
% covered by the electrical penalties
%
% Syntax
%
% [score, design, simoptions] = systempenalties_ROTARY(design, simoptions, score)
%
% 

    % support legacy code
    if isfield (simoptions, 'EfficiencyPenFactor') ...
            && ~isfield (simoptions, 'min_Efficiency_penfactor')
        simoptions.min_Efficiency_penfactor = simoptions.EfficiencyPenFactor;
    end

    % efficiency penalty
    design.EfficiencyPenalty = 0;

    if isfield(simoptions, 'addEfficiencyPenalty') 
        
        if ~isempty(simoptions.addEfficiencyPenalty) && simoptions.addEfficiencyPenalty
            
            optimiumEfficiency = design.RlVRp / (design.RlVRp + 1);

            simoptions = setfieldifabsent(simoptions, 'min_Efficiency_penfactor', [1, 0]);

            if isscalar(simoptions.min_Efficiency_penfactor)
                simoptions.min_Efficiency_penfactor = [simoptions.min_Efficiency_penfactor, 0];
            end

            design.EfficiencyPenalty = ...
                simoptions.min_Efficiency_penfactor(1) * (optimiumEfficiency-abs(design.Efficiency)) ...
                  + (simoptions.min_Efficiency_penfactor(2) * (optimiumEfficiency-abs(design.Efficiency)))^2;

            score = score + design.EfficiencyPenalty;
            
        end
        
    end
    
    % torque ripple penalty
    [score, design, simoptions] = ...
        addpenalty_AM(design, simoptions, 'upper', 'TorqueRippleFactor', design.BaseScore, score);

end