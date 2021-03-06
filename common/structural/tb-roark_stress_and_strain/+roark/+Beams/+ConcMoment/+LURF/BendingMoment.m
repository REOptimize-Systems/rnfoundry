function Mom = BendingMoment (Yvars, x)
% Calculates the moment in a beam with its left end free and its right end
% fixed, with an applied concentrated intermediate moment, as calculated in
% 'Roark's Formulas Stress & Strain'
%
% Input: 
%   
%   Yvars - (n x 1) column vector of values:
%     Yvars(:,1) - M0, applied moment at 'a'
%
%     The last column of YVars is:
%
%     Yvars(:,end) - a, distance from M_A at which 'M0' is applied 
%
%   x - row vector of position values at which the deflection is to be
%     calculated
%
% Output:
%
%   Mom - (n x 1) column vector of values of the moment at the
%     corresponding x position
%

    if size(Yvars,2) > 3
        error('Yvars has too many columns, Yvars must be a (n x 4) matrix')
    end
    
    M0 = Yvars(:,1);
%     l = Yvars(:,2);
    a = Yvars(:,end);
    
    Mom = zeros (size (Yvars,1), length (x));
    
    for j = 1:size (Yvars,1)
        for i = 1:length (x)  
            % Calculate the resulting moment in each case using the
            % generic formula
            Mom(j,i) = roark.Beams.ConcMoment.BendingMoment (0, 0, M0(j), x(i), a(j));
        end
    end
    
end