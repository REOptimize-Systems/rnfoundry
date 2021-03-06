function displaydesign_AM(design, simoptions)

    data = [ {'Rc'; 'Lc'; 'FF';'No. Stages';}, ...
             {design.CoilResistance; design.CoilInductance; design.CoilFillFactor; design.NStages;}, ...
             {'Wire D'; 'Coil Turns'; 'RlVRp'; 'No. Strands';}, ...
             {design.Dc; design.CoilTurns; design.RlVRp; design.NStrands;}, ...
             {'Branches'; 'CoilsPerBranch'; 'No. Machines'; ''}, ...
             {design.Branches; design.CoilsPerBranch; simoptions.NoOfMachines; []}, ...
           ];
        
    fprintf(1, 'Common design aspects:\n');
        
    displaytable(data, {}, 16);

end