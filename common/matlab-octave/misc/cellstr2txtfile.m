function cellstr2txtfile(file, strs)
% write all strings ain a cell array to a text file
%
% Syntax
%
% cellstr2txtfile(file, strs)
%


    if ~iscellstr(strs)
        error('strs must be cell array of strings')
    end
    
    [fid, message] = fopen(file, 'w');
    
    if fid == -1
        error(message);
    end
    
    for ind = 1:numel(strs)
        
        fprintf(fid, '%s\n', strs{ind});
        
    end
    
    fclose(fid);
    
end