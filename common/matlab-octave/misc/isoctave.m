function t = isoctave()
% ISOCTAVE.M
% ISOCTAVE  True if the operating environment is octave.
%    Usage: t=isoctave();
% 
%    Returns 1 if the operating environment is octave, otherwise
%    0 (Matlab)
% 
% ---------------------------------------------------------------
%
% COPYRIGHT : (c) NUHAG, Dept.Math., University of Vienna, AUSTRIA
%             http://nuhag.eu/
%             Permission is granted to modify and re-distribute this
%             code in any manner as long as this notice is preserved.
%             All standard disclaimers apply.

    if exist('OCTAVE_VERSION')
        % Only Octave has this variable.
        t=true;
    else
        t=false;
    end

end