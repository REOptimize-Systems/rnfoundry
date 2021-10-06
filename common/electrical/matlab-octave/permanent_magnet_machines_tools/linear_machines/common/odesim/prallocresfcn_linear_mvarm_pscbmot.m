function results = prallocresfcn_linear_mvarm_pscbmot(design, simoptions, T, Y)


    % test the size of the arrays needed for preallocation by calling the 
    [ ...
    	results.ydot(1,:), ...
        results.dpsidx(1,:), ...
        results.EMF(1,:), ...
        results.xT(1,:), ...
        results.vT(1,:), ...
        results.Fpto(1,:) ...
        results.Fa(1,:) ...
        results.Faddtrans(1,:) ...
    ] = prescribedmotodeforcefcn_linear_mvgarm(T(1), Y(1,:)', design, simoptions);
     
    % Now preallocate arrays of the correct sizes
    results.ydot = zeros(ceil(size(Y,1)/simoptions.ODESim.ResultsTSkip), size(results.ydot, 2));
    results.dpsidx = zeros(ceil(length(T)/simoptions.ODESim.ResultsTSkip), size(results.dpsidx, 2));
    results.EMF = zeros(ceil(length(T)/simoptions.ODESim.ResultsTSkip), size(results.EMF, 2));
    results.xT = zeros(ceil(length(T)/simoptions.ODESim.ResultsTSkip), size(results.xT, 2));
    results.vT = zeros(ceil(length(T)/simoptions.ODESim.ResultsTSkip), size(results.vT, 2));
    results.Fpto = zeros(ceil(length(T)/simoptions.ODESim.ResultsTSkip), size(results.Fpto, 2));
    results.Fa = zeros(ceil(length(T)/simoptions.ODESim.ResultsTSkip), size(results.Fa, 2));
    results.Faddtrans = zeros(ceil(length(T)/simoptions.ODESim.ResultsTSkip), size(results.Faddtrans, 2));

end