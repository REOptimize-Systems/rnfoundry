function [FemmProblem, nodes, links, info] = ...
    annularsecmagaperiodic(FemmProblem, thetapole, thetamag, rmag, roffset, pos, varargin)
% generates a periodic magnets containing region with an annular sector
% shape (i.e. a region bounded by two arcs and two straight lines, or a
% sector of an annulus) suitible for modelling radial flux machines.
%
% Syntax
%
% [FemmProblem, nodes, nodeids, links] = ...
%           annularsecmagaperiodic(FemmProblem, thetapole, thetamag, rmag, roffset, pos)
% [...] = annularsecmagaperiodic(..., 'Paramter', Value)
%
%
% Description
%
% annularsecmagaperiodic creates a periodic geometry of two magnets with
% spaces in between, with a base position shown in the figure below.
%
%             ********
%       ******        *                                    
%         *             *                                              
%           *        ****** 
%            *********     *                                            
%             *             *                                              
%               *             *                                                                                          
%                *             *                                              
%                  *    Mag 2    *                                                                                     
%                   *             *                                              
%                    *             *                                              
%                     *             *            
%                      ***************                                                                                          
%                       *             *                                              
%                        *             *  .........................
%                         *             *                ^
%                         *             *                 :
%                          *************** ..^.......      :                            
%                          *             *   :             :
%                           *             *   :             :                                                                          
%                           *             *   : thetamag    :                                    
%                           *    Mag 1    *    :             : thetapole             
%                            *             *   :             :                                      
%                            *             *   :             :            
%                            *             * . v.........     :                                       
%                             ***************                 :                                       
%                             *             *                 :               
%                             *             *                 v                
%  x                          *************** ..............................                                       
% r=0                         <------------->
%  :                               rmag
%  :                                :
%  :                                :
%  :            roffset             :
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
%  roffset - radial displacement of the magnet centers from the center
%
%  pos - the angular position of the magnets
%
%  In addition, a number of optional parameters can be specified as
%  parameter-value pairs. Possible parameter-value pairs are:
%
%  'MagDirections' - either a 2 element numeric vector, or a 2 element cell
%    array of strings. If numeric, these are the directions in degrees of
%    the magnet magnetisation. If a cell array of strings, these are
%    evaluated in the FEMM or xfemm lua interpreter to yield the magnet
%    direction in the magnet region elements. Variables that can be used in
%    these strings are:
%
%    'theta': angle in degrees of a line connecting the center of each
%             element with the origin 
%
%    'R'    : length of a line connecting the center of each element with the
%             origin
%
%    'x'    : x position of each element
%
%    'y'    : y position of each elements
% 
%    The default is {'theta', 'theta+180'}, resulting in radially
%    magnetized magnets of opposite polarity.
%
%  'MagnetMaterial' - 
%
%  'MagnetGroup' - 
%
%  'SpaceMaterial' - 
%
%  'SpaceGroup' - 
%
%  'Tol' - 
%
%  'MeshSize' - 
%
% Output
%
%  FemmProblem - 
%
%  nodes - 
%
%  nodeids - 
%
%  links - 
%
%  magblockinds - 
%
%

    Inputs.MagDirections = {'theta', 'theta+180'};
    Inputs.MagnetMaterial = 1;
    Inputs.MagnetGroup = 0;
    Inputs.SpaceMaterial = 1;
    Inputs.SpaceGroup = 0;
    Inputs.Tol = 1e-5;
    Inputs.MeshSize = -1;
    Inputs.BoundName = '';
    Inputs.NPolePairs = 1;

    Inputs = parse_pv_pairs (Inputs, varargin);
    
    if numel(Inputs.MagDirections) ~= 2*Inputs.NPolePairs
        if numel (Inputs.MagDirections) == 2
            Inputs.MagDirections = repmat (Inputs.MagDirections, 1, Inputs.NPolePairs);
        else
            error ('The number of magnet directions supplied is not appropriate');
        end
    end
    
    if isnumeric (Inputs.MagDirections) && isvector (Inputs.MagDirections)
        Inputs.MagDirections = {Inputs.MagDirections(1), Inputs.MagDirections(2)};
    end
    
    if (abs(Inputs.NPolePairs*thetapole - pi)*roffset) <= Inputs.Tol
        info.LinkTopBottom = true;
    else
        info.LinkTopBottom = false;
    end
    
    % get the number of existing nodes, segments, boundaries etc. if any
    elcount = elementcount_mfemm (FemmProblem);
    
    % add a periodic boundary for the edges of the magnets region
    if isempty (Inputs.BoundName)
        [FemmProblem, info.BoundaryInds] = addboundaryprop_mfemm (FemmProblem, ...
                                                'Rect Mags Periodic', 4);
    else
        BoundaryProp = newboundaryprop_mfemm (Inputs.BoundName, 4, false);
        info.BoundaryInds = elcount.NBoundaryProps + 1;
        FemmProblem.BoundaryProps(info.BoundaryInds) = BoundaryProp;
    end
    
    % construct the segments and label locations for the magnet regions
    % first in a linear fashoin which we will manipulate into the real
    % arced shape by modifying the node locations
    [nodes, ~, links, rectcentres, spacecentres] ...
        = rectregionsyperiodic (rmag, thetamag, (thetapole-thetamag), roffset, pos, ...
                                'Tol', Inputs.Tol, ...
                                'NodeCount', elcount.NNodes, ...
                                'NY1Pairs', Inputs.NPolePairs);
    
    % get the vertical links by finding those links where the difference in
    % y coordinates of the link nodes is not zero, these links must be made
    % into arc segments
    vertlinks = links(abs (diff ( [nodes(links(:,1)+1-elcount.NNodes,1), nodes(links(:,2)+1-elcount.NNodes,1)], 1, 2 )) < Inputs.Tol,:);
    angles = diff ( [nodes(vertlinks(:,1)+1-elcount.NNodes,2), nodes(vertlinks(:,2)+1-elcount.NNodes,2)], 1, 2);
    
    % get the horizontal links, these will be segments
    horizlinks = links(abs (diff ( [nodes(links(:,1)+1-elcount.NNodes,1), nodes(links(:,2)+1-elcount.NNodes,1)], 1, 2 )) >= Inputs.Tol,:);
    
    % transform the node locations to convert the rectangular region to the
    % desired arced region 
    [nodes(:,1), nodes(:,2)] = pol2cart (nodes(:,2), nodes(:,1));
    [rectcentres(:,1), rectcentres(:,2)] = pol2cart (rectcentres(:,2),rectcentres(:,1));
    [spacecentres(:,1), spacecentres(:,2)] = pol2cart (spacecentres(:,2),spacecentres(:,1));
    
    for i = 1:size(vertlinks,1)
        if angles(i) < 0
            vertlinks(i,:) = fliplr (vertlinks(i,:));
            angles(i) = abs (angles(i));
        end
    end
    
    % add all the nodes to the problem
    [FemmProblem, ~, info.NodeIDs] = addnodes_mfemm (FemmProblem, ...
                            nodes(:,1), nodes(:,2), 'InGroup', Inputs.MagnetGroup);
    
    if ~info.LinkTopBottom
        % Periodic boundary at bottom
        [FemmProblem, seginds] = addsegments_mfemm (FemmProblem, links(1,1), links(1,2), ...
            'BoundaryMarker', FemmProblem.BoundaryProps(info.BoundaryInds).Name, ...
            'InGroup', Inputs.MagnetGroup);
    else
        % normal segment at bottom without periodic boundary
        [FemmProblem, seginds] = addsegments_mfemm (FemmProblem, links(1,1), links(1,2), ...
            'InGroup', Inputs.MagnetGroup);
    end
    
    info.BottomSegInd = seginds;
        
    % Add all the segments except the top and bottom which will have
    % boundary properties we must set manually
    FemmProblem = addsegments_mfemm (FemmProblem, horizlinks(2:end-1,1), horizlinks(2:end-1,2), ...
        'InGroup', Inputs.MagnetGroup);
    
    % Add all the arc segments
    FemmProblem = addarcsegments_mfemm (FemmProblem, vertlinks(:,1), vertlinks(:,2), rad2deg(angles), ...
        'InGroup', Inputs.MagnetGroup);

    if info.LinkTopBottom
        % change the segments and arc segmetns linking to the last two
        % nodes to be added to be linked instead to the first two nodes
        seglinks = getseglinks_mfemm(FemmProblem);
        for ind = 1:size(seglinks,1)
            if seglinks(ind,1) == info.NodeIDs(end-1)
                FemmProblem.Segments(ind).n0 = info.NodeIDs(1);
            elseif seglinks(ind,2) == info.NodeIDs(end-1)
                FemmProblem.Segments(ind).n1 = info.NodeIDs(1);
            elseif seglinks(ind,1) == info.NodeIDs(end)
                FemmProblem.Segments(ind).n0 = info.NodeIDs(2);
            elseif seglinks(ind,2) == info.NodeIDs(end)
                FemmProblem.Segments(ind).n1 = info.NodeIDs(2);
            end
        end
        seglinks = getarclinks_mfemm(FemmProblem);
        for ind = 1:size(seglinks,1)
            if seglinks(ind,1) == info.NodeIDs(end-1)
                FemmProblem.ArcSegments(ind).n0 = info.NodeIDs(1);
            elseif seglinks(ind,2) == info.NodeIDs(end-1)
                FemmProblem.ArcSegments(ind).n1 = info.NodeIDs(1);
            elseif seglinks(ind,1) == info.NodeIDs(end)
                FemmProblem.ArcSegments(ind).n0 = info.NodeIDs(2);
            elseif seglinks(ind,2) == info.NodeIDs(end)
                FemmProblem.ArcSegments(ind).n1 = info.NodeIDs(2);
            end
        end
        % remove the unnecessary final 2 nodes
        FemmProblem.Nodes(end-1:end) = [];
        
        info.TopSegInd = info.BottomSegInd;
    else
        % Periodic boundary at top
        [FemmProblem, seginds] = addsegments_mfemm (FemmProblem, horizlinks(end,1), horizlinks(end,2), ...
            'BoundaryMarker', FemmProblem.BoundaryProps(info.BoundaryInds).Name, ...
            'InGroup', Inputs.MagnetGroup);
        
        info.TopSegInd = seginds;
    end
    
    % Now add the labels
    info.MagnetBlockInds = [];
    if ~isempty(Inputs.MagnetMaterial)
        
        % add the magnet labels
        for i = 1:size(rectcentres, 1)
            
            [recttheta, ~] = cart2pol (rectcentres(i,1),rectcentres(i,2));

            if rectcentres(i,3)
                
                if ischar (Inputs.MagDirections{2})
                    % specification must be a lua formula string, so pass
                    % it directly
                    [FemmProblem, info.MagnetBlockInds(end+1,1)] = addblocklabel_mfemm (FemmProblem, rectcentres(i,1), rectcentres(i,2), ...
                                                    'BlockType', FemmProblem.Materials(Inputs.MagnetMaterial).Name, ...
                                                    'MaxArea', Inputs.MeshSize, ...
                                                    'MagDir', Inputs.MagDirections{2}, ...
                                                    'InGroup', Inputs.MagnetGroup);
                else
                    % specification must be simple angle
                    [FemmProblem, info.MagnetBlockInds(end+1,1)] = addblocklabel_mfemm (FemmProblem, rectcentres(i,1), rectcentres(i,2), ...
                                                    'BlockType', FemmProblem.Materials(Inputs.MagnetMaterial).Name, ...
                                                    'MaxArea', Inputs.MeshSize, ...
                                                    'MagDir', Inputs.MagDirections{2} + rad2deg (recttheta), ...
                                                    'InGroup', Inputs.MagnetGroup);
                                            
                end
                
            else

                if ischar (Inputs.MagDirections{1})
                    % specification must be a lua formula string, so pass
                    % it directly
                    [FemmProblem, info.MagnetBlockInds(end+1,1)] = addblocklabel_mfemm (FemmProblem, rectcentres(i,1), rectcentres(i,2), ...
                                                    'BlockType', FemmProblem.Materials(Inputs.MagnetMaterial).Name, ...
                                                    'MaxArea', Inputs.MeshSize, ...
                                                    'MagDir', Inputs.MagDirections{1}, ...
                                                    'InGroup', Inputs.MagnetGroup);
                else
                    % specification must be simple angle
                    [FemmProblem, info.MagnetBlockInds(end+1,1)] = addblocklabel_mfemm (FemmProblem, rectcentres(i,1), rectcentres(i,2), ...
                                                    'BlockType', FemmProblem.Materials(Inputs.MagnetMaterial).Name, ...
                                                    'MaxArea', Inputs.MeshSize, ...
                                                    'MagDir', Inputs.MagDirections{1} + rad2deg (recttheta), ...
                                                    'InGroup', Inputs.MagnetGroup);
                end

            end
            
            info.MagnetBlockInds(end, 2) = rectcentres(i,3);

        end
    
    end
    
    info.SpaceBlockInds = [];
    if ~isempty(Inputs.SpaceMaterial)
        % Add the other labels
        
        for i = 1:size(spacecentres, 1)

            [FemmProblem, info.SpaceBlockInds(end+1,1)] = addblocklabel_mfemm (FemmProblem, spacecentres(i,1), spacecentres(i,2), ...
                                            'BlockType', FemmProblem.Materials(Inputs.SpaceMaterial).Name, ...
                                            'MaxArea', Inputs.MeshSize, ...
                                            'InGroup', Inputs.SpaceGroup);

        end
    
    end

    
end