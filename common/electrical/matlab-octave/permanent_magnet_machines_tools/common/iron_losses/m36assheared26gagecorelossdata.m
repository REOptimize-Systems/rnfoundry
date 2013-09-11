function [fq, Bq, Pq] = m36assheared26gagecorelossdata(dointerp)
% returns table of losses per kg in M-36 AS Sheared 26 Gage Steel
% laminations at a number of frequencies and field strengths in Tesla
%
% Syntax
%
% [fq, Bq, Pq] = m36assheared26gagecorelossdata()
% [fq, Bq, Pq] = m36assheared26gagecorelossdata(dointerp)
%
% 

    if nargin < 1
        dointerp = true;
    end
    
    m36density = 7500; % kg / m^3
    freqs = [10,20,30,50,60,100,150,200,300,400,600,1000,1500,2000;];
    tesla = [0.100000000000000;0.200000000000000;0.400000000000000;0.700000000000000;1;1.20000000000000;1.30000000000000;1.40000000000000;1.50000000000000;1.55000000000000;1.60000000000000;1.65000000000000;1.70000000000000;];
    lossperkg = [0.00313056040000000,0.00663590620000000,0.0104498988000000,0.0191361016000000,0.0238980808000000,0.0456356340000000,0.0793663200000000,0.119710866000000,0.217595994000000,0.337306860000000,0.661386000000000,1.51016470000000,3.08646800000000,4.73993300000000;0.0135804592000000,0.0286600600000000,0.0451947100000000,0.0820118640000000,0.102514830000000,0.194667946000000,0.330693000000000,0.493834880000000,0.879643380000000,1.35143206000000,2.57940540000000,5.59973480000000,10.7585456000000,16.6448810000000;0.0460765580000000,0.0987669760000000,0.156968944000000,0.288143834000000,0.360896294000000,0.694455300000000,1.19710866000000,1.79015144000000,3.19669900000000,4.89425640000000,9.14917300000000,19.6872566000000,37.2580780000000,58.6428920000000;0.112435620000000,0.242508200000000,0.390217740000000,0.729729220000000,0.921531160000000,1.80999302000000,3.17465280000000,4.82811780000000,8.79643380000000,13.6686440000000,25.7940540000000,58.2019680000000,114.199316000000,185.629004000000;0.198415800000000,0.432105520000000,0.696659920000000,1.31615814000000,1.67110196000000,3.35102240000000,6.01861260000000,9.28145020000000,17.4164980000000,27.5577500000000,53.7927280000000,126.765650000000,260.145160000000,423.287040000000;0.271168260000000,0.590838160000000,0.954600460000000,1.80999302000000,2.30162328000000,4.65174820000000,8.48778700000000,13.2277200000000,25.3531300000000,40.7854700000000,80.9095540000000,196.431642000000,405.650080000000,659.181380000000;0.317465280000000,0.690046060000000,1.11333310000000,2.10761672000000,2.68081792000000,5.44541140000000,9.92079000000000,15.5425710000000,29.9828320000000,48.5016400000000,97.6646660000000,240.303580000000,493.834880000000,NaN;0.370376160000000,0.806890920000000,1.30293042000000,2.46696978000000,3.13717426000000,6.34930560000000,11.5742550000000,18.1440226000000,35.0534580000000,56.6587340000000,114.860702000000,284.395980000000,586.428920000000,NaN;0.438719380000000,0.952395840000000,1.53882476000000,2.91009840000000,3.69494312000000,7.47366180000000,13.5584130000000,21.2525368000000,41.0059320000000,66.3590620000000,NaN,NaN,NaN,NaN;0.473993300000000,1.03176216000000,1.66889734000000,3.15260660000000,4.00358992000000,8.09095540000000,14.6827692000000,22.9280480000000,44.3128620000000,71.6501500000000,NaN,NaN,NaN,NaN;0.511471840000000,1.11333310000000,1.79676530000000,3.39291018000000,4.29680438000000,8.68620280000000,15.7850792000000,24.6917440000000,47.3993300000000,76.9412380000000,NaN,NaN,NaN,NaN;0.546745760000000,1.18608556000000,1.91361016000000,3.60896294000000,4.56356340000000,9.23735780000000,16.7992044000000,26.2349780000000,NaN,NaN,NaN,NaN,NaN,NaN;0.573201200000000,1.24561030000000,2.01061344000000,3.79415102000000,4.80607160000000,9.72237420000000,17.6590062000000,27.5577500000000,NaN,NaN,NaN,NaN,NaN,NaN;];
    losspervol = lossperkg .* m36density; % (P / kg) * (kg / m^3) = P / m^3
    
    if dointerp

        lossperkgnonans = infillpower(freqs, losspervol);

        % add a row of zeros along the top
        losspervolnonans = [zeros(1, size(losspervolnonans, 2)); losspervolnonans];
        losspervolnonans = [zeros(size(losspervolnonans, 1), 1), losspervolnonans];

        % ensure row vectors
        freqs = freqs(:);
        tesla = tesla(:);

        % add zero values for freq and tesla
        freqs = [0; freqs];
        tesla = [0; tesla];

        % make a grid of interpolation points
        fi = linspace(min(freqs), max(freqs), 15); 
        Bi = linspace(min(tesla), max(tesla), 15);
        [fq,Bq] = meshgrid(fi,Bi);

        losspervollist = reshape(losspervolnonans, [], 1);

        Blist = repmat(tesla, numel(freqs), 1);

        freqlist = reshape(repmat(freqs(:)', [], numel(tesla)), [], 1);

        Pq = griddata(freqlist,Blist,losspervollist,fq,Bq);

        Pq(1,:) = 0;
        Pq(:,1) = 0;
    
    else
        
        [fq,Bq,Pq] = table2vectors(freqs,tesla,losspervol,true);
        
    end

end

