function status = odesimoutputfcns_AM (t, y, flag, design, simoptions)
% evaluate a collection of outputfcns in an ode simulation
    
    compnames = fieldnames (simoptions.ODESim.SolutionComponents);

    status = zeros (size(compnames));
    
    for ind = 1:numel (compnames)

        if isfield (simoptions.ODESim.SolutionComponents.(compnames{ind}), 'OutputFcn') ...
                && ~isempty (simoptions.ODESim.SolutionComponents.(compnames{ind}).OutputFcn)
            
            if isempty (flag)
                status(ind) = feval (simoptions.ODESim.SolutionComponents.(compnames{ind}).OutputFcn, ...
                                     t, y(simoptions.ODESim.SolutionComponents.(compnames{ind}).SolutionIndices,end), ...
                                     flag, design, simoptions);
                             
            else
                status(ind) = feval (simoptions.ODESim.SolutionComponents.(compnames{ind}).OutputFcn, ...
                                     t, y, flag, design, simoptions);
                
            end

        end

    end
    
    status = any (status(:));

end