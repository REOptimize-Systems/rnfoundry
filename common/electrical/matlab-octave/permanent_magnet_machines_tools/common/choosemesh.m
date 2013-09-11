function meshsize = choosemesh(w, h, fraction)
% choosemesh selects an appropriate mesh size for a rectangular region
%
    
    if nargin < 3
        fraction = 0.05;
    end

    % The mesh size is the minimum of either the diagonal of a rectangular
    % region bounded by a box of width w and height h, divided by the
    % desired number of triangles, or 5 times the width or height
    % divided by the desired number of triangles
    meshsize = min([5*w*fraction, 5*h*fraction, sqrt(w^2 + h^2)*fraction]);

end