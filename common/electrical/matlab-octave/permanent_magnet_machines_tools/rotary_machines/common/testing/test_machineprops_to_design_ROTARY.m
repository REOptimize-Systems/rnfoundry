

Rphase = 0.7250;
Lphase = 0.0091;
FluxPhasePeak = 2.6281;
Poles = 32;
Qc = 24;

[design, simoptions] = machineprops_to_design_ROTARY ( Rphase, ...
                                                       Lphase, ...
                                                       Poles, ...
                                                       Qc, ...
                                                       'FluxPhasePeak', FluxPhasePeak, ...
                                                       'yd', 1, ...
                                                       'CoilLayers', 2 );



