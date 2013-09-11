function [results, design] = resfun_linear_pscbmot(T, Y, design, simoptions)

    results = prallocresfcn_linear_pscbmot(design, simoptions, T, Y);
    
    for i = 1:size(T,1)
    
        [ ...
            results.ydot(i,:), ...
            results.dpsidx(i,:), ...
            results.EMF(i,:), ...
            results.xT(i,:), ...
            results.vT(i,:), ...
            results.Fpto(i,:) ...
         ] = simplelinearmachineode_proscribedmotion(T(i), Y(i,:)', design, simoptions);
    
    end
    
    design.xAmax = 0;

    design = odeelectricalresults(T, Y(:,1), results.EMF(:,1), design, simoptions);

end
