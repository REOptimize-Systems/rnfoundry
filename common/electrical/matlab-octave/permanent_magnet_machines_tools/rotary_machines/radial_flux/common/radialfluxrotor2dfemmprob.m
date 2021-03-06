function [FemmProblem, info] = radialfluxrotor2dfemmprob(thetapole, thetamag, rmag, rbackiron, drawnrotors, rrotor, varargin)
% adds the outermost rotor parts of a radial flux machine to a FemmProblem
% Structure
%
%
% radialfluxrotor2dfemmprob creates a geometry 
% with spaces in between, with a base position shown in the figure below.
% In addition, any number of annular sectors can be added either to inside
% or outside of the main region (like wrappers for the main region).
%                       
%             ********
%      *******        *                                    
%    **   *             *                                              
%     *     *        ****** 
%       *    *********     *                                            
%        *    *             *                                              
%          *    *             *                                                                                          
%           *    *             *                                              
%             *    *    Mag 2    *                                                                                     
%              *    *             *                                              
%               *    *             *                                              
%                *    *             *            
%                 *    ***************                                                                                          
%                  *    *             *                                              
%                   *    *             *  .........................
%                    *    *             *                ^
%                    *    *             *                 :
%                     *    *************** ..^.......      :                            
%                     *    *             *   :             :
%                      *    *             *   :             :                                                                          
%                      *    *             *   : thetamag    :                                    
%                       *   *    Mag 1    *    :             : thetapole             
%                       *    *             *   :             :                                      
%                       *    *             *   :             :            
%                       *    *             * . v.........     :                                       
%                        *    ***************                 :                                       
%                        *    *             *                 :               
%                        *    *             *                 v                
%  x                     ******************** ..............................                                       
% r=0                    <---><------------->
%  :                 rbackiron     rmag
%  :                                :
%  :                                :
%  :            rrotor              :
%  :------------------------------->:
%  :           
%
%
% This geometry is drawn in a periodic way in the tangential direction,
% 'wrapping' around at the top and bottom. 
%
% Inputs
%
%  FemmProblem - FemmProblem structure to which the geometry will be added
%
%  thetapole - pole width in radians
%
%  thetamag - magnet width in radians
%
%  rmag - radial thickness of the magnets
%
%  rrotor - radial displacement of the magnet centers from the center
%
%  pos - the angular position of the magnets
%

    Inputs.DrawingType = 'MagnetRotation';
    Inputs.NPolePairs = 1;
    Inputs.MagArrangement = 'NS';
    Inputs.PolarisationType = 'constant';
    Inputs.FemmProblem = newproblem_mfemm('planar');
    Inputs.Position = 0;
    Inputs.FractionalPolePosition = [];
    Inputs.RotorAnglePosition = [];
    Inputs.MagnetMaterial = 1;
    Inputs.BackIronMaterial = 1;
    Inputs.OuterRegionsMaterial = 1;
    Inputs.MagnetSpaceMaterial = 1;
    Inputs.MagnetGroup = [];
    Inputs.MagnetSpaceGroup = [];
    Inputs.BackIronGroup = [];
    Inputs.OuterRegionGroup = [];
    Inputs.MagnetRegionMeshSize = -1;
    Inputs.BackIronRegionMeshSize = -1;
    Inputs.OuterRegionsMeshSize = [-1, -1];
    Inputs.Tol = 1e-5;
    Inputs.DrawOuterRegions = true;
    Inputs.XShift = 0;
    Inputs.YShift = 0;
    
    Inputs = parse_pv_pairs(Inputs, varargin);
    
    FemmProblem = Inputs.FemmProblem;
    
    elcount = elementcount_mfemm (FemmProblem);
   
    if isscalar(Inputs.MagnetGroup) 
        
        FemmProblem = addgroup_mfemm(FemmProblem, 'Magnet', Inputs.MagnetGroup);
        
        Inputs.MagnetGroup = repmat(Inputs.MagnetGroup, 1, 2);
        
    elseif isempty(Inputs.MagnetGroup)
        
        if ~isfield (FemmProblem.Groups, 'Magnet')
            [FemmProblem, Inputs.MagnetGroup] = addgroup_mfemm(FemmProblem, 'Magnet');
        else
            Inputs.MagnetGroup = FemmProblem.Groups.Magnet;
        end
         
        if drawnrotors(1) && drawnrotors(2)
            Inputs.MagnetGroup = [Inputs.MagnetGroup,Inputs.MagnetGroup+1];
        else
            Inputs.MagnetGroup = repmat(Inputs.MagnetGroup, 1, 2);
        end
    end
    
    if isscalar(Inputs.MagnetSpaceGroup)
        FemmProblem = addgroup_mfemm(FemmProblem, 'MagnetSpace', Inputs.MagnetSpaceGroup);
        Inputs.MagnetSpaceGroup = repmat(Inputs.MagnetSpaceGroup, 1, 2);
    elseif isempty(Inputs.MagnetSpaceGroup)
        if ~isfield (FemmProblem.Groups, 'MagnetSpace')
            [FemmProblem, Inputs.MagnetSpaceGroup] = addgroup_mfemm(FemmProblem, 'MagnetSpace');
        else
            Inputs.MagnetSpaceGroup = FemmProblem.Groups.MagnetSpace;
        end
        Inputs.MagnetSpaceGroup = repmat(Inputs.MagnetSpaceGroup, 1, 2);
    end
    
    if isscalar(Inputs.BackIronGroup)
        FemmProblem = addgroup_mfemm(FemmProblem, 'RotorBackIron', Inputs.BackIronGroup);
        Inputs.BackIronGroup = repmat(Inputs.BackIronGroup, 1, 2);
    elseif isempty(Inputs.BackIronGroup)
        if ~isfield (FemmProblem.Groups, 'BackIron')
            [FemmProblem, Inputs.BackIronGroup] = addgroup_mfemm(FemmProblem, 'RotorBackIron');
        else
            Inputs.BackIronGroup = FemmProblem.Groups.BackIron;
        end
        Inputs.BackIronGroup = repmat(Inputs.BackIronGroup, 1, 2);
    end
    
    if isscalar(Inputs.OuterRegionGroup)
        FemmProblem = addgroup_mfemm(FemmProblem, 'BackIronOuterRegion', Inputs.OuterRegionGroup);
        Inputs.OuterRegionGroup = repmat(Inputs.OuterRegionGroup, 1, 2);
    elseif isempty(Inputs.OuterRegionGroup)
        if ~isfield (FemmProblem.Groups, 'BackIronOuterRegion')
            [FemmProblem, Inputs.OuterRegionGroup] = addgroup_mfemm(FemmProblem, 'BackIronOuterRegion');
        else
            Inputs.OuterRegionGroup = FemmProblem.Groups.BackIronOuterRegion;
        end
        Inputs.OuterRegionGroup = repmat(Inputs.OuterRegionGroup, 1, 2);
    end
    
    if numel(Inputs.OuterRegionsMeshSize) ~= 2
        error('AXIALFLUXOUTERROTOR2DFEMMPROB:badoutermeshspec', ...
            'OuterRegionsMeshSize must be a two element vector');
    end
    
    if strncmpi(Inputs.PolarisationType, 'constant', 1)
        
        switch Inputs.MagArrangement
            
            case 'NN'
                
                innerMagDirections = {180, 0};
                
            case 'NS'
                
                innerMagDirections = {0, 180};
                
            otherwise
                
                error('ROTARY:radiafluxrotor:badtype', ...
                    'Unknown magnet arrangement specification, should be NN or NS.');
                
        end
    
    elseif strncmpi(Inputs.PolarisationType, 'radial', 1);
        
        switch Inputs.MagArrangement

            case 'NN'

                innerMagDirections = {'theta', 'theta+180'};

            case 'NS'

                innerMagDirections = {'theta+180', 'theta'};

            otherwise

                error('ROTARY:radiafluxrotor:badtype', ...
                      'Unknown magnet arrangement specification, should be NN or NS.')

        end
    
    else
        error('Unknown magnet polarisation type.');
    end

    if drawnrotors(1) && ~drawnrotors(2)
        roffset = [rrotor + rmag/2, 0];
    elseif ~drawnrotors(1) && drawnrotors(2)
        roffset = [0, rrotor - rmag/2];
    elseif drawnrotors(1) && drawnrotors(2)
        roffset = [rrotor(1)+rmag/2, rrotor(2)-rmag/2];
    else
        error('ROTARY:radiafluxrotor:badtype', ...
              'At least one rotor part must be drawn.');
    end
  
    % Get the planar position from the position specification
    Inputs.Position = planarrotorpos(thetapole, ...
                                     Inputs.Position, ...
                                     Inputs.FractionalPolePosition, ...
                                     Inputs.RotorAnglePosition);
    
    
    % Add a proscribed A boundary we will use for the outer regions
    % boundary types
    [FemmProblem, boundind] = addboundaryprop_mfemm(FemmProblem, 'Outer Boundary Pros A', 0, 'A0', 0);
            
    linktb1 = false;
    linktb2 = false;
    info.NodeIDs1 = [];
    info.NodeIDs2 = [];
    info.MagnetBlockInds1 = [];
    info.SpaceBlockInds1 = [];
    info.MagnetBoundaryInds1 = [];
    info.MagnetBlockInds2 = [];
    info.SpaceBlockInds2 = [];
    info.MagnetBoundaryInds2 = [];
    
    if drawnrotors(1)
        % an outer rotor
        
        % there will be three wrapper thicknesses on either side, the back
        % iron, and some air region
        info.OuterWrapperThickness = [ 0, rbackiron; ];
        wrappergroups = [ nan, Inputs.BackIronGroup(1); ];
        if Inputs.DrawOuterRegions
            info.OuterWrapperThickness = [ info.OuterWrapperThickness;
                                      0, 2*(rbackiron + rmag);
                                      0, 4*(rbackiron + rmag) ];
                                  
            wrappergroups = [ wrappergroups; 
                              nan, Inputs.OuterRegionGroup(1); 
                              nan, Inputs.OuterRegionGroup(1) ];
        end
        

        % draw the outer rotor parts
        [FemmProblem, ~, rotorinfo1] ...
                = wrappedannularsecmagaperiodic ( FemmProblem, thetapole, ...
                                                  thetamag, rmag, roffset(1), ...
                                                  Inputs.Position, info.OuterWrapperThickness, ...
                                                  'MagnetMaterial', Inputs.MagnetMaterial, ...
                                                  'MagDirections', fliplr(innerMagDirections), ...
                                                  'SpaceMaterial', Inputs.MagnetSpaceMaterial, ...
                                                  'SpaceGroup', Inputs.MagnetSpaceGroup(1), ...
                                                  'MagnetGroup', Inputs.MagnetGroup(1), ...
                                                  'WrapperGroup', wrappergroups, ...
                                                  'Tol', Inputs.Tol, ...
                                                  'MeshSize', Inputs.MagnetRegionMeshSize, ...
                                                  'NPolePairs', Inputs.NPolePairs);


        info.NodeIDs1 = rotorinfo1.NodeIDs;
        info.MagnetBlockInds1 = rotorinfo1.MagnetBlockInds;
        info.SpaceBlockInds1 = rotorinfo1.SpaceBlockInds;
        info.MagnetBoundaryInds1 = rotorinfo1.BoundaryInds;
        
        if Inputs.DrawOuterRegions && ~linktb1
            % the last arc segment added will be the outermost segment, so give it the
            % proscribed A boundary
            FemmProblem.ArcSegments(end).BoundaryMarker = FemmProblem.BoundaryProps(boundind).Name;
            FemmProblem.ArcSegments(end-1).BoundaryMarker = FemmProblem.BoundaryProps(boundind).Name;
        end
    end
    
    if drawnrotors(2)
        % an inner rotor
        
        % mirror the wrapper thicknesses on the other side
        innerwrapperthickness = [ rbackiron, 0; ];
        wrappergroups = [ Inputs.BackIronGroup(2), nan; ];
        if Inputs.DrawOuterRegions
            innerwrapperthickness = [ innerwrapperthickness;
                                      (roffset(2)-rbackiron-rmag/2) * 0.2, 0;
                                      (roffset(2)-rbackiron-rmag/2) * 0.3, 0 ];
            wrappergroups = [ wrappergroups; 
                              Inputs.OuterRegionGroup(2), nan; 
                              Inputs.OuterRegionGroup(2), nan ];
        end
        
        [FemmProblem, ~, rotorinfo2] ...
                = wrappedannularsecmagaperiodic ( FemmProblem, thetapole, ...
                                                  thetamag, rmag, roffset(2), ...
                                                  Inputs.Position, innerwrapperthickness, ...
                                                  'MagnetMaterial', Inputs.MagnetMaterial, ...
                                                  'MagDirections', innerMagDirections, ...
                                                  'SpaceMaterial', Inputs.MagnetSpaceMaterial, ...
                                                  'SpaceGroup', Inputs.MagnetSpaceGroup(2), ...
                                                  'MagnetGroup', Inputs.MagnetGroup(2), ...
                                                  'WrapperGroup', wrappergroups, ...
                                                  'Tol', Inputs.Tol, ...
                                                  'MeshSize', Inputs.MagnetRegionMeshSize, ...
                                                  'NPolePairs', Inputs.NPolePairs);

        if rotorinfo2.LinkTopBottom
            % add a label to the centre with no mesh
            FemmProblem = addblocklabel_mfemm (FemmProblem, 0, 0, 'BlockType', '<No Mesh>');
        end
            
        info.NodeIDs2 = rotorinfo2.NodeIDs;
        info.MagnetBlockInds2 = rotorinfo2.MagnetBlockInds;
        info.SpaceBlockInds2 = rotorinfo2.SpaceBlockInds;
        info.MagnetBoundaryInds2 = rotorinfo2.BoundaryInds;
        
        if Inputs.DrawOuterRegions && ~linktb2
            % Again, the last arc segment added should be the outermost boundary
            % segment this time on the rhs, so give it the proscribed boundary condition
            FemmProblem.ArcSegments(end).BoundaryMarker = FemmProblem.BoundaryProps(boundind).Name;
            FemmProblem.ArcSegments(end-1).BoundaryMarker = FemmProblem.BoundaryProps(boundind).Name;
        end

    end
    
    info.outerblockinds = [];
    
    % Add the back iron block labels
    if ~isempty(Inputs.BackIronMaterial)
        
        if drawnrotors(1)
            [x,y] = pol2cart(Inputs.NPolePairs*thetapole, roffset(1) + rmag/2 + rbackiron/2);
            [FemmProblem, info.outerblockinds(end+1)] = addblocklabel_mfemm(FemmProblem, x, y, ...
                                                        'BlockType', FemmProblem.Materials(Inputs.BackIronMaterial).Name, ...
                                                        'MaxArea', Inputs.BackIronRegionMeshSize, ...
                                                        'InGroup', Inputs.BackIronGroup(1));
        end
                                                
        if drawnrotors(2)
            [x,y] = pol2cart(Inputs.NPolePairs*thetapole, roffset(2) - rmag/2 - rbackiron/2);
            [FemmProblem, info.outerblockinds(end+1)] = addblocklabel_mfemm(FemmProblem, x, y, ...
                                                        'BlockType', FemmProblem.Materials(Inputs.BackIronMaterial).Name, ...
                                                        'MaxArea', Inputs.BackIronRegionMeshSize, ...
                                                        'InGroup', Inputs.BackIronGroup(2));
        end
        
    end
             
    if Inputs.DrawOuterRegions && ~isempty(Inputs.OuterRegionsMaterial)
        
        % Add the outer region block lables
        if drawnrotors(1)
            
            [x,y] = pol2cart( Inputs.NPolePairs*thetapole,  roffset(1) + rmag/2 + rbackiron + info.OuterWrapperThickness(2,2)/2);
            [FemmProblem, info.outerblockinds(end+1)] = addblocklabel_mfemm(FemmProblem, x, y, ...
                                              'BlockType', FemmProblem.Materials(Inputs.OuterRegionsMaterial).Name, ...
                                              'MaxArea', Inputs.OuterRegionsMeshSize(1), ...
                                              'InGroup', Inputs.OuterRegionGroup(1));
                                                    
            [x,y] = pol2cart(Inputs.NPolePairs*thetapole, roffset(1) + rmag/2 + rbackiron + info.OuterWrapperThickness(2,2) + info.OuterWrapperThickness(3,2)/2);
            [FemmProblem, info.outerblockinds(end+1)] = addblocklabel_mfemm(FemmProblem, x, y, ...
                                              'BlockType', FemmProblem.Materials(Inputs.OuterRegionsMaterial).Name, ...
                                              'MaxArea', Inputs.OuterRegionsMeshSize(2), ...
                                              'InGroup', Inputs.OuterRegionGroup(1));    

        end
        
        if drawnrotors(2) 
            
            [x,y] = pol2cart(Inputs.NPolePairs*thetapole, roffset(2) - rmag/2 - rbackiron - innerwrapperthickness(2,1)/2);
            [FemmProblem, info.outerblockinds(end+1)] = addblocklabel_mfemm(FemmProblem, x, y, ...
                                              'BlockType', FemmProblem.Materials(Inputs.OuterRegionsMaterial).Name, ...
                                              'MaxArea', Inputs.OuterRegionsMeshSize(1), ...
                                              'InGroup', Inputs.OuterRegionGroup(2));

            [x,y] = pol2cart(Inputs.NPolePairs*thetapole, roffset(2) - rmag/2 - rbackiron - innerwrapperthickness(2,1) - innerwrapperthickness(3,1)/2);
            [FemmProblem, info.outerblockinds(end+1)] = addblocklabel_mfemm(FemmProblem, x, y, ...
                                              'BlockType', FemmProblem.Materials(Inputs.OuterRegionsMaterial).Name, ...
                                              'MaxArea', Inputs.OuterRegionsMeshSize(2), ...
                                              'InGroup', Inputs.OuterRegionGroup(2));
        end
        
    end

    if drawnrotors(1) && drawnrotors(2)
        info.MagnetCornerIDs = [info.NodeIDs1([1,end-1]), info.NodeIDs2([2,end])];
        info.TopSegInds = [rotorinfo1.TopSegInd, rotorinfo2.TopSegInd];
        info.BottomSegInds = [rotorinfo1.BottomSegInd, rotorinfo2.BottomSegInd];
    elseif drawnrotors(1)
        info.MagnetCornerIDs = info.NodeIDs1([1,end-1]);
        info.TopSegInds = rotorinfo1.TopSegInd;
        info.BottomSegInds = rotorinfo1.BottomSegInd;
    elseif drawnrotors(2)
        info.MagnetCornerIDs = info.NodeIDs2([2,end]);
        info.TopSegInds = rotorinfo2.TopSegInd;
        info.BottomSegInds = rotorinfo2.BottomSegInd;
    end
    
    info.LinkTopBottom = linktb1 || linktb2;
    
    % shift all new nodes and block labels in X and Y if requested
    if Inputs.XShift ~= 0 || Inputs.YShift ~= 0
        
        newelcount = elementcount_mfemm (FemmProblem);
        
        nodeids = (elcount.NNodes):(newelcount.NNodes-1);
        
        FemmProblem = translatenodes_mfemm(FemmProblem, Inputs.XShift, Inputs.YShift, nodeids);
        
        blockids = (elcount.NBlockLabels):(newelcount.NBlockLabels-1);
                 
        FemmProblem = translateblocklabels_mfemm(FemmProblem, Inputs.XShift, Inputs.YShift, blockids);
        
    end
    
end