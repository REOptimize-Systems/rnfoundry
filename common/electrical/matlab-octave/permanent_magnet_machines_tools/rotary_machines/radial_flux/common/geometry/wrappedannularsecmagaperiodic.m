function [FemmProblem, wrapperthickness, info] = ...
    wrappedannularsecmagaperiodic(FemmProblem, thetapole, thetamag, rmag, roffset, pos, wrapperthickness, varargin)
% creates a FemmProblem geometry of a radial section containing one or more
% pairs of magnets optionally wrapped with additional layers
%
%
% Syntax
%
% [FemmProblem, wrapperthickness, innercentres, outercentres, nodeids] = ...
%   wrappedannularsecmagaperiodic(FemmProblem, thetapole, thetamag, rmag, ...
%                                 roffset, pos, wrapperthickness)
%
% [...] = wrappedannularsecmagaperiodic(..., 'param', value, ...)
%
% Description
%
% wrappedannularsecmagaperiodic creates a geometry of two magnets with
% spaces in between, with a base position shown in the figure below. In
% addition, any number of annular sectors can be added either to inside or
% outside of the main region (like wrappers for the main region). If the
% angle swept out by the section is less than a full circle periodic
% boundary will be added to the segments at either end of the geometry. If
% it is a full circle, the geometry will be linked at the start and end to
% complete this circular region.
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
%                  /    *             *                                              
%                 / *    *             *  .........................
%                /   *    *             *                ^
%               /    *    *             *                 :
%              /      *    *************** ..^.......      :                            
%             /       *    *             *   :             :
%            /         *    *             *   :             :                                                                          
%           /          *    *             *   : thetamag    :                                    
%          /            *   *    Mag 1    *    :             : thetapole             
%   single internal     *    *             *   :             :                                      
%   wrapper example     *    *             *   :             :            
%                       *    *             * . v.........     :                                       
%                        *    ***************                 :                                       
%                        *    *             *                 :               
%                        *    *             *                 v                
%  x                     ******************** ..............................                                       
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
%  roffset - radial displacement of the magnet centers from the origin
%
%  pos - the angular position of the magnets
%
%  wrapperthickness - either an (n x 2) matrix or column vector of wrapper
%    thicknesses. If an (n x 2) matrix. the first column specifies the
%    thickness of any desired wrapper on the left of the magnets, and the
%    second column the thickness of wrappers on the right hand side. The
%    wrappers are added moving progressively further from the magnet
%    position (either to the left or right) down the rows of the matrix.
%    Wrappers with thicknesses less than a tolerance are not added. The
%    default tolerance is 1e-5, but this value can be changed using the
%    appropriate optional parameter value pair (see below). If
%    wrapperthickness is a column vector the same thicknesses are used on
%    both sides.
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
%  wrapperthickness - 
%
%  info - information about the geometry packaged into a structure
%
%


    Inputs.MagDirections = {'theta', 'theta+180'};
    Inputs.MagnetMaterial = 1;
    Inputs.MagnetGroup = 0;
    Inputs.SpaceMaterial = 1;
    Inputs.SpaceGroup = 0; 
    Inputs.WrapperGroup = 0;
    Inputs.Tol = 1e-5;
    Inputs.MeshSize = -1;
    Inputs.NPolePairs = 1;

    % parse the input arguments
    Inputs = parse_pv_pairs(Inputs, varargin);
    
    if isscalar(Inputs.WrapperGroup)
        Inputs.WrapperGroup = repmat (Inputs.WrapperGroup, size(wrapperthickness));
    elseif ~samesize(wrapperthickness, Inputs.WrapperGroup)
        error ('Your must supply either a scalar wrapper group, or a vector the smame size as the number of wrappers.')
    end
    
    if isnumeric(Inputs.MagDirections) && isvector(Inputs.MagDirections)
        Inputs.MagDirections = {Inputs.MagDirections(1), Inputs.MagDirections(2)};
    end
    
    % remove input fields specific to this function and pass the
    % remaining fields to planarrectmagaperiodic as a series of p-v pairs
    planarrectmagaperiodicInputs = rmfield(Inputs, {'WrapperGroup'});
    
    % Convert the inputs structure to a series of p-v pairs
    planarrectmagaperiodicInputs = struct2pvpairs(planarrectmagaperiodicInputs);
    
    % first draw periodic magnet regions
    [FemmProblem, nodes, ~, info] = annularsecmagaperiodic ( FemmProblem, ...
                                                             thetapole, ...
                                                             thetamag, ...
                                                             rmag, ...
                                                             roffset, ...
                                                             pos, ...
                                                             planarrectmagaperiodicInputs{:}, ...
                                                             'NPolePairs', Inputs.NPolePairs);                    
    
%     % Now correct the magnet angles which are specified as numeric values,
%     % and therefore represent angles relative to a normal pointing in the
%     % direction of the magnet block label
%     for ind = 1:size(info.MagnetBlockInds, 1)
%         if ~isempty(FemmProblem.BlockLabels(info.MagnetBlockInds(ind)).MagDir) ...
%                 && isscalar(FemmProblem.BlockLabels(info.MagnetBlockInds(ind)).MagDir) ...
%                 && isempty(FemmProblem.BlockLabels(info.MagnetBlockInds(ind)).MagDirFctn)
%             
%             [maglabeltheta, ~] = cart2pol(FemmProblem.BlockLabels(info.MagnetBlockInds(ind)).Coords(1), ...
%                                     FemmProblem.BlockLabels(info.MagnetBlockInds(ind)).Coords(2));
%                 
%             FemmProblem.BlockLabels(info.MagnetBlockInds(ind)).MagDir = ...
%                 FemmProblem.BlockLabels(info.MagnetBlockInds(ind)).MagDir + rad2deg(maglabeltheta);
%         
%         end
%     end
    
    % now add the back iron nodes and links, depending on their thicknesses
    if size(wrapperthickness,2) < 2
        wrapperthickness = [wrapperthickness, wrapperthickness];
    elseif size(wrapperthickness,2) > 2
        error('wrapperthickness must be a scaler or a (1 x 2) vector or (n x 2) matrix')
    end
    
%     if anyalldims(wrapperthickness < 0)
%         error('wrapper thicknesses must all be greater that 0')
%     end
    
    elcount = elementcount_mfemm(FemmProblem);
    
    info.InnerCentres = zeros(size(wrapperthickness)) * NaN;
    
    % wrapperthickness(1,1) is the first inner region thickness
    if wrapperthickness(1,1) > Inputs.Tol
        % add the nodes and segments for the inner side
        %
        %                        |   /
        %  wrapperthickness      |  /
        % * sin(2*thetapole)     | /. 2*thetapole
        %                        |/__.__
        %
        %                     wrapperthickness 
        %                     * cos(2*thetapole)
        %
        
        if wrapperthickness(1,1) > roffset
            error('wrapper thickness cannot be greater than magnet inner radius.');
        end
        
        innerrad = roffset - rmag/2 - wrapperthickness(1,1);
        
        % First node is to left of first node in 'nodes' matrix. this is at
        % the bottom of the sim
        [FemmProblem, ~, botnodeid] = addnodes_mfemm(FemmProblem, ...
                            innerrad, ...
                            0, ...
                            'InGroup', Inputs.WrapperGroup(1,1));
        
        
        
        if info.LinkTopBottom
            lastbotnodeid = elcount.NNodes - size(nodes,1) + 2;
            topnodeid = botnodeid;
            botboundarymarker = '';
        else
            
            % Second node is to left of penultimate node in 'nodes' matrix
            [x,y] = pol2cart(Inputs.NPolePairs*2*thetapole, innerrad);
            [FemmProblem, ~, topnodeid] = addnodes_mfemm(FemmProblem, ...
                                 x, ...
                                 y, ...
                                'InGroup', Inputs.WrapperGroup(1,1));

            % add a new periodic boundary for the top and bottom of the region
            [FemmProblem, info.BoundaryInds(end+1)] = addboundaryprop_mfemm(FemmProblem, 'Left Wrap Annular Sec Mags Periodic', 4);

            botboundarymarker = FemmProblem.BoundaryProps(info.BoundaryInds(end)).Name;
            
            % Seg with Periodic boundary at top
            [FemmProblem, segind] = addsegments_mfemm(FemmProblem, ...
                                            elcount.NNodes - 2, ...
                                            topnodeid, ...
                                            'BoundaryMarker', FemmProblem.BoundaryProps(info.BoundaryInds(end)).Name, ...
                                            'InGroup', Inputs.WrapperGroup(1,1));
                                        
            info.TopSegInd = [info.TopSegInd, segind];
                                        
            lastbotnodeid = elcount.NNodes - size(nodes,1);
            
        end
        
        % Seg at bottom
        [FemmProblem, segind] = addsegments_mfemm(FemmProblem, ...
                                        lastbotnodeid, ...
                                        botnodeid, ...
                                        'BoundaryMarker', botboundarymarker, ...
                                        'InGroup', Inputs.WrapperGroup(1,1));

        info.BottomSegInd = [info.BottomSegInd, segind];
        
        % Add a node at the mid-point of the wrapper, the purpose of this
        % is to ensure an arc segmetn is never more than 180 degrees which
        % causes problems
        [x,y] = pol2cart(Inputs.NPolePairs*thetapole, innerrad);
        [FemmProblem, ~, midnodeid] = addnodes_mfemm(FemmProblem, ...
                                        x, ...
                                        y, ...
                                        'InGroup', Inputs.WrapperGroup(1,1));
                        
        % Seg joining top and bottom (the two most recently added nodes)
        FemmProblem = addarcsegments_mfemm( FemmProblem, ...
                                            botnodeid, ...
                                            midnodeid, ...
                                            rad2deg(Inputs.NPolePairs*thetapole), ...
                                            'InGroup', Inputs.WrapperGroup(1,1) );
                                        
        % Seg joining top and bottom (the two most recently added nodes)
        FemmProblem = addarcsegments_mfemm( FemmProblem, ...
                                            midnodeid, ...
                                            topnodeid, ...
                                            rad2deg(Inputs.NPolePairs*thetapole), ...
                                            'InGroup', Inputs.WrapperGroup(1,1) );
                    
        [info.InnerCentres(1,1), info.InnerCentres(1,2)] = pol2cart(Inputs.NPolePairs*thetapole, innerrad+wrapperthickness(1,1)/2);
        
    else
        % Set the region thickness to be exactly zero so this can be tested
        % later
        wrapperthickness(1,1) = 0;
    end
    
    % now add all subsequent inner wrappers
    for i = 2:size(wrapperthickness, 1)
        
        if wrapperthickness(i,1) > Inputs.Tol
            
            innerrad = innerrad - wrapperthickness(i,1);
        
            if innerrad < Inputs.Tol
                error('Inner wrapper radii must all be greater than tolerance.')
            end
            
            lastbotnodeid = botnodeid;
            lasttopnodeid = topnodeid;
            
            % First node is to left of first node in 'nodes' matrix. this is at
            % the bottom of the sim
            [FemmProblem, ~, botnodeid] = addnodes_mfemm(FemmProblem, ...
                                innerrad, ...
                                0, ...
                                'InGroup', Inputs.WrapperGroup(i,1));
   
            if info.LinkTopBottom
                topnodeid = botnodeid;
                botboundarymarker = '';
            else
                
                % Second node is to left of penultimate node in 'nodes' matrix
                [x,y] = pol2cart(Inputs.NPolePairs*2*thetapole, innerrad);
                [FemmProblem, ~, topnodeid] = addnodes_mfemm(FemmProblem, ...
                                     x, ...
                                     y, ...
                                    'InGroup', Inputs.WrapperGroup(i,1));

                % add a new periodic boundary for the top and bottom of the region
                [FemmProblem, info.BoundaryInds(end+1)] = addboundaryprop_mfemm(FemmProblem, 'Left Wrap Annular Sec Mags Periodic', 4);

                botboundarymarker = FemmProblem.BoundaryProps(info.BoundaryInds(end)).Name;
                
                % Seg with Periodic boundary at top
                [FemmProblem, segind] = addsegments_mfemm(FemmProblem, ...
                                                lasttopnodeid, ...
                                                topnodeid, ...
                                                'BoundaryMarker', botboundarymarker, ...
                                                'InGroup', Inputs.WrapperGroup(i,1));
                                            
                info.TopSegInd = [info.TopSegInd, segind];

            end
            
            % Seg at bottom
            [FemmProblem, segind] = addsegments_mfemm(FemmProblem, ...
                                            lastbotnodeid, ...
                                            botnodeid, ...
                                            'BoundaryMarker', botboundarymarker, ...
                                            'InGroup', Inputs.WrapperGroup(i,1));

            info.BottomSegInd = [info.BottomSegInd, segind];
            
            % Add a node at the mid-point of the wrapper, the purpose of this
            % is to ensure an arc segmetn is never more than 180 degrees which
            % causes problems
            [x,y] = pol2cart(Inputs.NPolePairs*thetapole, innerrad);
            [FemmProblem, ~, midnodeid] = addnodes_mfemm(FemmProblem, ...
                                            x, ...
                                            y, ...
                                            'InGroup', Inputs.WrapperGroup(i,1));
                                    
            % Seg joining top and bottom (the two most recently added nodes)
            FemmProblem = addarcsegments_mfemm( FemmProblem, ...
                                                botnodeid, ...
                                                midnodeid, ...
                                                rad2deg(Inputs.NPolePairs*thetapole), ...
                                                'InGroup', Inputs.WrapperGroup(i,1) );

            % Seg joining top and bottom (the two most recently added nodes)
            FemmProblem = addarcsegments_mfemm( FemmProblem, ...
                                                midnodeid, ...
                                                topnodeid, ...
                                                rad2deg(Inputs.NPolePairs*thetapole), ...
                                                'InGroup', Inputs.WrapperGroup(i,1) );
            
            [info.InnerCentres(i,1), info.InnerCentres(i,2)] = pol2cart(Inputs.NPolePairs*thetapole, innerrad+wrapperthickness(i,1)/2);
            
        else
            wrapperthickness(i,1) = 0;
        end
        
    end
    
    info.OuterCentres = zeros(size(wrapperthickness)) * NaN;
    
    % wrapperthickness(1,2) is the first outer region thickness
    if wrapperthickness(1,2) > Inputs.Tol
        
        outerrad = roffset + rmag/2 + wrapperthickness(1,2);

        % First node is to right of second node in 'nodes' matrix. this is at
        % the bottom of the sim
        [FemmProblem, ~, botnodeid] = addnodes_mfemm(FemmProblem, ...
                                     outerrad, ...
                                     0, ...
                                     'InGroup', Inputs.WrapperGroup(1,2));

        if info.LinkTopBottom
            lastbotnodeid = elcount.NNodes - size(nodes,1) + 3;
            topnodeid = botnodeid;
            botboundarymarker = '';
        else
            % Second node is to left of penultimate node in 'nodes' matrix
            [x,y] = pol2cart(Inputs.NPolePairs*2*thetapole, outerrad);
            [FemmProblem, ~, topnodeid] = addnodes_mfemm(FemmProblem, ...
                                         x, ...
                                         y, ...
                                        'InGroup', Inputs.WrapperGroup(1,2));

            % add a new periodic boundary for the top and bottom of the
            % region
            [FemmProblem, info.BoundaryInds(end+1)] = addboundaryprop_mfemm(FemmProblem, 'Right Wrap Annular Sec Mags Periodic', 4);

            botboundarymarker = FemmProblem.BoundaryProps(info.BoundaryInds(end)).Name;
            
            % Seg with Periodic boundary at top
            [FemmProblem, segind] = addsegments_mfemm( FemmProblem, ...
                                             elcount.NNodes - 1, ...
                                             topnodeid, ...
                                             'BoundaryMarker', FemmProblem.BoundaryProps(info.BoundaryInds(end)).Name, ...
                                             'InGroup', Inputs.WrapperGroup(1,2) );
                                         
            info.TopSegInd = [info.TopSegInd, segind];
        
            lastbotnodeid = elcount.NNodes - size(nodes,1) + 1;
        end
        
        % Seg at bottom
        [FemmProblem, segind] = addsegments_mfemm( FemmProblem, ...
                                         lastbotnodeid, ...
                                         botnodeid, ...
                                         'BoundaryMarker', botboundarymarker, ...
                                         'InGroup', Inputs.WrapperGroup(1,2));

        info.BottomSegInd = [info.BottomSegInd, segind];
        
        % Add a node at the mid-point of the wrapper, the purpose of this
        % is to ensure an arc segment is never more than 180 degrees which
        % causes problems
        [x,y] = pol2cart(Inputs.NPolePairs*thetapole, outerrad);
        [FemmProblem, ~, midnodeid] = addnodes_mfemm(FemmProblem, ...
                                            x, ...
                                            y, ...
                                            'InGroup', Inputs.WrapperGroup(1,2));

        % Seg joining top and bottom (the two most recently added nodes)
        FemmProblem = addarcsegments_mfemm( FemmProblem, ...
                                            botnodeid, ...
                                            midnodeid, ...
                                            rad2deg(Inputs.NPolePairs*thetapole), ...
                                            'InGroup', Inputs.WrapperGroup(1,2) );

        % Seg joining top and bottom (the two most recently added nodes)
        FemmProblem = addarcsegments_mfemm( FemmProblem, ...
                                            midnodeid, ...
                                            topnodeid, ...
                                            rad2deg(Inputs.NPolePairs*thetapole), ...
                                            'InGroup', Inputs.WrapperGroup(1,2) );

        [info.OuterCentres(1,1), info.OuterCentres(1,2)] = pol2cart(Inputs.NPolePairs*thetapole, outerrad-wrapperthickness(1,2)/2);
        
    else
        % Set the region thickness to be exactly zero so this can be tested
        % later
        wrapperthickness(1,2) = 0;
    end
    
    % now add all subsequent right hand wrappers
    for i = 2:size(wrapperthickness, 1)
        
        if wrapperthickness(i,2) > Inputs.Tol
            
            outerrad = outerrad + wrapperthickness(i,2);
            
            lastbotnodeid = botnodeid;
            lasttopnodeid = topnodeid;

            % First node is to right of second node in 'nodes' matrix. this is at
            % the bottom of the sim
            [FemmProblem, ~, botnodeid] = addnodes_mfemm(FemmProblem, ...
                                         outerrad, ...
                                         0, ...
                                         'InGroup', Inputs.WrapperGroup(i,2));

            if info.LinkTopBottom
                topnodeid = botnodeid;
                botboundarymarker = '';
            else
                % Second node is to left of penultimate node in 'nodes' matrix
                [x,y] = pol2cart(Inputs.NPolePairs*2*thetapole, outerrad);
                [FemmProblem, ~, topnodeid] = addnodes_mfemm(FemmProblem, ...
                                             x, ...
                                             y, ...
                                            'InGroup', Inputs.WrapperGroup(i,2));

                % add a new periodic boundary for the top and bottom of the
                % region
                [FemmProblem, info.BoundaryInds(end+1)] = addboundaryprop_mfemm(FemmProblem, 'Right Wrap Annular Sec Mags Periodic', 4);

                botboundarymarker = FemmProblem.BoundaryProps(info.BoundaryInds(end)).Name;
                
                % Seg with Periodic boundary at top
                [FemmProblem, segind] = addsegments_mfemm( FemmProblem, ...
                                                 lasttopnodeid, ...
                                                 topnodeid, ...
                                                 'BoundaryMarker', FemmProblem.BoundaryProps(info.BoundaryInds(end)).Name, ...
                                                 'InGroup', Inputs.WrapperGroup(i,2) );
                                             
                info.TopSegInd = [info.TopSegInd, segind];
                
            end
            
            % Seg at bottom
            [FemmProblem, segind] = addsegments_mfemm( FemmProblem, ...
                                             lastbotnodeid, ...
                                             botnodeid, ...
                                             'BoundaryMarker', botboundarymarker, ...
                                             'InGroup', Inputs.WrapperGroup(i,2) );

            info.BottomSegInd = [info.BottomSegInd, segind];
            
            % Add a node at the mid-point of the wrapper, the purpose of this
            % is to ensure an arc segmetn is never more than 180 degrees which
            % causes problems
            [x,y] = pol2cart(Inputs.NPolePairs*thetapole, outerrad);
            [FemmProblem, ~, midnodeid] = addnodes_mfemm(FemmProblem, ...
                                            x, ...
                                            y, ...
                                            'InGroup', Inputs.WrapperGroup(i,2));

            % Seg joining top and bottom (the two most recently added nodes)
            FemmProblem = addarcsegments_mfemm( FemmProblem, ...
                                                botnodeid, ...
                                                midnodeid, ...
                                                rad2deg(Inputs.NPolePairs*thetapole), ...
                                                'InGroup', Inputs.WrapperGroup(i,2) );

            % Seg joining top and bottom (the two most recently added nodes)
            FemmProblem = addarcsegments_mfemm( FemmProblem, ...
                                                midnodeid, ...
                                                topnodeid, ...
                                                rad2deg(Inputs.NPolePairs*thetapole), ...
                                                'InGroup', Inputs.WrapperGroup(i,2) );
            
            [info.OuterCentres(i,1), info.OuterCentres(i,2)] = pol2cart(Inputs.NPolePairs*thetapole, outerrad-wrapperthickness(i,2)/2);
            
        else
            wrapperthickness(i,2) = 0;
        end
        
    end

end
