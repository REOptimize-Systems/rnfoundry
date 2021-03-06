% Test_polyholemagperiodic.m

thetapole = 2*pi / 20; 
thetamag = thetapole * 0.8;
rmag = 0.02;
roffset = 0.5;

%% cases

test = 3;

switch test

    case 1
        % no displacement
        pos = 0;

    case 2
        % B top on top
        pos = (thetapole - thetamag)/2;

    case 3
        % A bot on bottom
        pos = -(thetapole - thetamag)/2;

    case 4
        % halway B
        pos = (thetamag/2 + (thetapole - thetamag)/2);

    case 5
        % halway A
        pos = -(thetamag/2 + (thetapole - thetamag)/2);

    case 6
        % B bot on bot 
        pos = (thetamag + (thetapole - thetamag)/2);

    case 7
        % A top on top
        pos = -(thetamag + (thetapole - thetamag)/2);
        
    case 8
        % one period translation
        % A bot B top
        pos = 2*(thetamag + (thetapole - thetamag));       
        
    case 9
        % -ve one period translation
        % A bot B top
        pos = -2*(thetamag + (thetapole - thetamag));   
        
    case 10
        % half period translation
        % A top B bot
        pos = (thetamag + (thetapole - thetamag));     
        
    case 11
        % -ve half period translation
        % A top B bot
        pos = -(thetamag + (thetapole - thetamag)); 

    case 12
        % 10% pole translation
        pos =  (thetapole/5);        
        
end

%%
FemmProblem = newproblem_mfemm('planar');

%   Materials
%Matlib = parsematlib_mfemm(fullfile(fileparts(which('mfemm_parsematlib.m')), 'matlib.dat'));

load('matlib.mat');

FemmProblem.Materials = matlib([1, 47, 2]);

[FemmProblem, nodes, nodeids, links] = ...
    polyholemagperiodic(FemmProblem, thetapole, thetamag, rmag, roffset, pos);

% plotnodelinks(nodes, links)

openprobleminfemm_mfemm (FemmProblem);
