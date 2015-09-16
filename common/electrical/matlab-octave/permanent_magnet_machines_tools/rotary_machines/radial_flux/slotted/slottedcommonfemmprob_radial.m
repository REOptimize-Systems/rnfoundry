function [FemmProblem, info] = slottedcommonfemmprob_radial(FemmProblem, design, ...
                            Inputs, magcornerids, Rs, coillabellocs, inslabellocs, ...
                            yokenodeids, ymidpoint, BackIronMatInd, YokeMatInd, CoilMatInd, ...
                            GapMatInd, linktb, XShift, YShift )
% Constructs common aspects of a slotted mfemm radial flux FemmProblem
% structure
%
% Syntax
%
% FemmProblem = slottedcommonfemmprob_radial(FemmProblem, design, ...
%                             Inputs, gapedgenodes, Rs, coillabellocs, yokenodeids, ...
%                             ymidpoint, BackIronMatInd, YokeMatInd, CoilMatInd
%                             Inputs.ArmatureBackIronGroup, linktb, GapMatInd, drawouterregions)
%
%  
% Description
%
% slottedcommonfemmprob_radial performs some final problem creation tasks
% common to all radial flux type rotary machines. These tasks include
% drawing the inner or outer air regions and linking up and adding boundary
% conditions to the simulation. This is a low-level function intended for
% use by the main radial flux machine problem creation functions rather
% than direct use.
%

    elcount = elementcount_mfemm (FemmProblem);
    
    slotsperpole = design.Qs / design.Poles;
    
    Inputs = setfieldifabsent (Inputs, 'DrawingType', '2PoleMagnetRotation');

    % define the block properties of the core region
    yokeBlockProps.BlockType = FemmProblem.Materials(YokeMatInd).Name;
    yokeBlockProps.MaxArea = Inputs.BackIronRegionMeshSize;
    yokeBlockProps.InCircuit = '';
    yokeBlockProps.InGroup = Inputs.ArmatureBackIronGroup;

    % Prototype an array of segprops structures
    SegProps.MaxSideLength = -1;
    SegProps.Hidden = 0;
    SegProps.InGroup = 0;
    SegProps.BoundaryMarker = '';
    
    SegProps = repmat(SegProps, 1, 4);
    
    coilBlockProps.BlockType = FemmProblem.Materials(CoilMatInd).Name;
    coilBlockProps.MaxArea = Inputs.CoilRegionMeshSize;
    coilBlockProps.InCircuit = '';
    coilBlockProps.InGroup = Inputs.CoilGroup;

    % draw the positive part of the coil circuit
    coilBlockProps.Turns = design.CoilTurns;
    
    statorirongp = getgroupnumber_mfemm (FemmProblem, 'StatorIronOutline');
    
    % add circuits for each winding phase
    for i = 1:design.Phases
        cname = num2str(i);
        if ~hascircuit_mfemm (FemmProblem, cname)
            FemmProblem = addcircuit_mfemm (FemmProblem, cname);
        end
        FemmProblem = setcircuitcurrent (FemmProblem, cname, Inputs.CoilCurrent(i));
    end

    edgenodes = [];
    
    
    switch Inputs.DrawingType
        
        case '2PoleMagnetRotation'
            
            % Beware all ye who enter here!!
            switch Inputs.ArmatureType

                case 'external'
                    % single inner facing stator (magnets inside, stator outside)

                    routerregion = [2*design.tm, 10*design.tm]; 

                    [edgenodes(:,1), edgenodes(:,2)] = pol2cart ( ...
                                                                 [ 0; ...
                                                                   0; ...
                                                                   0; ...
                                                                   0; ...
                                                                   0; ...
                                                                   design.thetap * 2; ...
                                                                   design.thetap * 2; ...
                                                                   design.thetap * 2; ...
                                                                   design.thetap * 2; ...
                                                                   design.thetap * 2 ], ...
                                                                 [ design.Rmo; ...
                                                                   design.Rmo+design.g; ...
                                                                   Rs + design.ty/2; ...
                                                                   Rs + design.ty/2 + routerregion(1); ...
                                                                   Rs + design.ty/2 + routerregion(1) + routerregion(2); ...
                                                                   Rs + design.ty/2 + routerregion(1) + routerregion(2); ...
                                                                   Rs + design.ty/2 + routerregion(1); ...
                                                                   Rs + design.ty/2; ...
                                                                   design.Rmo+design.g;
                                                                   design.Rmo; ] ...
                                                                 ); 

                    % add the nodes to the problem
                    [FemmProblem, nodeinds, nodeids] = addnodes_mfemm (FemmProblem, edgenodes(2:9,1), edgenodes(2:9,2));

                    % add arcs linking the outer segments
                    FemmProblem = addarcsegments_mfemm (FemmProblem, ...
                                                        nodeids(2), ...
                                                        nodeids(7), ...
                                                        rad2deg(repmat(2*design.thetap,1,1)));

                    % put the stator iron segment in the right group
                    FemmProblem.ArcSegments(end).InGroup = statorirongp;

                    % add segments with periodic boundaries on the outer parts
                    [FemmProblem, boundind(1), boundnames{1}] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Back Iron Periodic', 4);
                    [FemmProblem, boundind(end+1), boundnames{end+1}] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Outer Periodic', 4);
                    [FemmProblem, boundind(end+1), boundnames{end+1}] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Outer Periodic', 4);
                    [FemmProblem, boundind(end+1), boundnames{end+1}] = addboundaryprop_mfemm (FemmProblem, 'Radial Air Gap Periodic', 4);

                    segprops = struct ('BoundaryMarker', boundnames, 'InGroup', {statorirongp, 0, 0, 0});

                    % bottom segs
                    [FemmProblem, info.BottomSegInds] = addsegments_mfemm (FemmProblem, ...
                                                                           nodeids(1), ...
                                                                           nodeids(2), ...
                                                                           segprops(1));
                    % top segs
                    [FemmProblem, info.TopSegInds] = addsegments_mfemm (FemmProblem, ...
                                                                        nodeids(8), ...
                                                                        nodeids(7), ...
                                                                        segprops(1));

                    % bottom gap corner to bottom core corner
                    [FemmProblem, info.BottomSegInds(end+1)] = addsegments_mfemm (FemmProblem, nodeids(1), magcornerids(1), ...
                                                       'BoundaryMarker', boundnames{4});

                    % top gap corner to top core corner
                    [FemmProblem, info.TopSegInds(end+1)] = addsegments_mfemm (FemmProblem, nodeids(end), magcornerids(2), ...
                                                       'BoundaryMarker', boundnames{4});

                    % bottom slot to edge
                    FemmProblem = addarcsegments_mfemm (FemmProblem, nodeids(1), yokenodeids(1), ...
                                                        rad2deg(((2*pi/design.Qs)-design.thetac(1))/2), ...
                                                        'InGroup', statorirongp);

                    % top slot to edge
                    FemmProblem = addarcsegments_mfemm (FemmProblem, yokenodeids(4), nodeids(end), ...
                                                        rad2deg(((2*pi/design.Qs)-design.thetac(1))/2), ...
                                                        'InGroup', statorirongp);

                    if Inputs.DrawOuterRegions

                        % bottom segs
                        [FemmProblem, info.BottomSegInds(end+1:end+2)] = addsegments_mfemm (FemmProblem, ...
                                                        nodeids([2,3]), ...
                                                        nodeids([3,4]), ...
                                                        segprops(2:3));
                        % top segs
                        [FemmProblem, info.TopSegInds(end+1:end+2)] = addsegments_mfemm (FemmProblem, ...
                                                        nodeids([7,6]), ...
                                                        nodeids([6,5]), ...
                                                        segprops(2:3));

                        % add arcs linking the outer segments
                        FemmProblem = addarcsegments_mfemm (FemmProblem, ...
                                                           nodeids([3,4]), ...
                                                           nodeids([6,5]), ...
                                                           rad2deg(repmat(2*design.thetap,1,2)));

                        % Add block labels for the outer air regions
                        [labelloc(1),labelloc(2)]  = pol2cart (design.thetap, Rs + design.ty/2 + routerregion(1)/2);

                        FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                                'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                                'MaxArea', Inputs.OuterRegionsMeshSize(1));

                        [labelloc(1),labelloc(2)]  = pol2cart(design.thetap, Rs + design.ty/2 + routerregion(1) + routerregion(2)/2);

                        FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                                'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                                'MaxArea', Inputs.OuterRegionsMeshSize(2));

                    else
                        % remove the nodes that would have been used to make the
                        % outer regions
                        FemmProblem = deletenode_mfemm (FemmProblem, nodeinds(3:6)-1);

                    end


                case 'internal'
                    % single outer facing stator (stator inside, magnets outside)

                    routerregion = [0.8*design.Ryi, 0.5*design.Ryi]; 

                    [edgenodes(:,1), edgenodes(:,2)] = pol2cart (  ...
                                                                 [ 0; ...
                                                                   0; ...
                                                                   0; ...
                                                                   0; ...
                                                                   0; ...
                                                                   design.thetap * 2; ...
                                                                   design.thetap * 2; ...
                                                                   design.thetap * 2; ...
                                                                   design.thetap * 2; ...
                                                                   design.thetap * 2; ...
                                                                   design.thetap; ...
                                                                   design.thetap; ...
                                                                   design.thetap ], ...
                                                                 [ design.Rmi; ...
                                                                   design.Rmi-design.g; ...
                                                                   design.Ryi; ...
                                                                   routerregion(1); ...
                                                                   routerregion(2); ...
                                                                   routerregion(2); ...
                                                                   routerregion(1); ...
                                                                   design.Ryi; ...
                                                                   design.Rmi-design.g;
                                                                   design.Rmi; ...
                                                                   design.Ryi; ...
                                                                   routerregion(1); ...
                                                                   routerregion(2); ] ...
                                                                 ); 



                    if linktb

                       % add the nodes to the problem
                       [FemmProblem, nodeinds, nodeids] = addnodes_mfemm (FemmProblem, ...
                                                                      edgenodes([2:5,11:13],1), ...
                                                                      edgenodes([2:5,11:13],2));

                        links = [ nodeids([2,5,3,6,4,7]); ...
                                  nodeids([5,2,6,3,7,4]) ];

                        topnodeid = nodeids(1);

                        arcangle = design.thetap;
                        statorironinds = [1, 2]; % TODO: this is probably not right

                    else
                        % add the nodes to the problem
                        [FemmProblem, nodeinds, nodeids] = addnodes_mfemm (FemmProblem, ...
                                                                      edgenodes(2:9,1), ...
                                                                      edgenodes(2:9,2));

                        links = [ nodeids([2,3,4]); ...
                                  nodeids([7,6,5]) ];
                        topnodeid = nodeids(8);
                        arcangle = 2*design.thetap;
                        statorironinds = 1;
                    end

                    % add arcs linking the outer segments
                    [FemmProblem, arcseginds] = addarcsegments_mfemm (FemmProblem, ...
                                                       links(1,:), ...
                                                       links(2,:), ...
                                                       rad2deg(repmat(arcangle,size(links))));

                    % put the stator iron arc segments in the right group
                    for i = 1:numel(statorironinds)
                        FemmProblem.ArcSegments(arcseginds(statorironinds(i))).InGroup = statorirongp;
                    end

                    if linktb
                        boundnames = repmat({''}, 1,4);
                        segprops = struct('BoundaryMarker', boundnames, 'InGroup', {statorirongp, 0, 0, 0});
                    else
                        % add segments with periodic boundaries on the outer parts
                        [FemmProblem, boundind(1), boundnames{1}] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Back Iron Periodic', 4);
                        [FemmProblem, boundind(end+1), boundnames{end+1}] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Outer Periodic', 4);
                        [FemmProblem, boundind(end+1), boundnames{end+1}] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Outer Periodic', 4);
                        [FemmProblem, boundind(end+1), boundnames{end+1}] = addboundaryprop_mfemm (FemmProblem, 'Radial Air Gap Periodic', 4);

                        segprops = struct ('BoundaryMarker', boundnames, 'InGroup', {statorirongp, 0, 0, 0});

                        % top segs
                        [FemmProblem, info.TopSegInds] = addsegments_mfemm (FemmProblem, ...
                                                        nodeids([8,7,6]), ...
                                                        nodeids([7,6,5]), ...
                                                        segprops(1:3));
                    end

                    % bottom segs
                    [FemmProblem, info.BottomSegInds] = addsegments_mfemm (FemmProblem, ...
                                                    nodeids([1,2,3]), ...
                                                    nodeids([2,3,4]), ...
                                                    segprops(1:3));



                    % bottom gap corner to bottom core corner
                    [FemmProblem, info.BottomSegInds(end+1)] = addsegments_mfemm (FemmProblem, nodeids(1), magcornerids(1), ...
                                                       'BoundaryMarker', boundnames{4});

                    if ~linktb
                        % top gap corner to top core corner
                        [FemmProblem, info.TopSegInds(end+1)] = addsegments_mfemm (FemmProblem, topnodeid, magcornerids(2), ...
                                                           'BoundaryMarker', boundnames{4});
                    end
                    % bottom slot to edge
                    FemmProblem = addarcsegments_mfemm (FemmProblem, nodeids(1), yokenodeids(2), ...
                                                       rad2deg(((2*pi/design.Qs)-design.thetac)/2), ...
                                                       'InGroup', statorirongp);

                    % top slot to edge
                    FemmProblem = addarcsegments_mfemm (FemmProblem, yokenodeids(3), topnodeid, ...
                                                       rad2deg(((2*pi/design.Qs)-design.thetac)/2), ...
                                                       'InGroup', statorirongp);


                    % Add block labels for the outer air regions
                    [labelloc(1),labelloc(2)]  = pol2cart (design.thetap, ...
                                                    routerregion(1) + (Rs - design.ty/2 - routerregion(1))/2 );

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                            'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                            'MaxArea', Inputs.OuterRegionsMeshSize(1));

                    [labelloc(1),labelloc(2)]  = pol2cart (design.thetap, ...
                                                            routerregion(2) + (routerregion(1) - routerregion(2))/2);

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                            'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                            'MaxArea', Inputs.OuterRegionsMeshSize(2));

                    if linktb
                        FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (0, 0, ...
                                            'BlockType', '<No Mesh>');
                    end

                case 'di'
                    % double internal stator (mags on outside)
        %             drawnrotors = [true, true];
        %             rrotor = [ design.Rmo, design.Rmo + 2* (design.g + design.tc + design.ty/2) ];
        %             drawnstatorsides = [1, 1];
        %             Rs = design.Rmo(1) + design.g + design.tc + design.ty/2;
                    error('not yet supported');
                case 'do'
                    % double outer/external stator (mags on inside)
                    error('not yet supported');

                otherwise
                    error('Unrecognised ArmatureType option.')

            end
        
        case 'Full'
            

            
            
        otherwise
            
            error('Unrecognised DrawingType option.')
            
    end
        

    switch Inputs.ArmatureType
        
        case 'external'
            
            % Add block labels for the air gap
            [labelloc(1),labelloc(2)]  = pol2cart (design.thetap, design.Rmo+design.g/2);

            FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm ( labelloc(1,1), labelloc(1,2), ...
                                    'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                    'MaxArea', Inputs.AirGapMeshSize );

            % add a block label for the yoke and teeth
            [labelloc(1),labelloc(2)] = pol2cart (design.thetap, Rs);

            FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                                                 yokeBlockProps);
            
        case 'internal'
            
            % Add block labels for the air gap
            [labelloc(1),labelloc(2)] = pol2cart (design.thetap, design.Rmi-design.g/2);

            FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                    'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                    'MaxArea', Inputs.AirGapMeshSize);
            
            % add a block label for the yoke and teeth
            [labelloc(1),labelloc(2)] = pol2cart (design.thetap, Rs);

            FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                                                 yokeBlockProps);
                                                             
        otherwise
            error('Unrecognised ArmatureType option.')
            
    end

    % add block labels for the coils
    row = 1;
% 
%     % create an array to hold the coil information for every slot in the
%     % drawing
%     circnums = zeros(design.Qcb*(3-design.CoilLayers), 1);
%     % enumerate the machine phases
%     temp = (1:design.Phases)';
% 
%     if design.yd == 1
%         % short pitched (concentrated) winding, adjacent slots hold the
%         % same winding
%         for ii = 1:2:numel(circnums)
%             % go through every slot in the drawing getting the phase lying
%             % in that slot
%             circnums(ii) = temp(1);
% 
%             if  ii < numel (circnums)
%                 % for a slot pitch of 1, the neighbouring slot will have
%                 % the other side of the phase in it
%                 circnums(ii+1) = temp(1);
%             end
%             % rotate the phase list to get to the next one
%             temp = circshift (temp, [1, 0]);
% 
%         end
% 
%     else
%         % otherwise next slot contains the next phase, and so on in
%         % sequence
%         for ii = 1:numel(circnums)
% 
%             circnums(ii) = temp(1);
% 
%             temp = circshift(temp, [1,0]);
% 
%         end
% 
%     end
% 
%     % create a matrix to hold the information for all layers
%     docircname = zeros(numel(circnums), Inputs.NWindingLayers);
% 
%     if design.yd == 1
% 
%         for ii = 1:2:size (docircname,1)
% 
%             if ii <= numel(circnums)
% 
%                 docircname(ii,:) = [1, zeros(1, Inputs.NWindingLayers-1)];
% 
%             end
% 
%             if ii+design.yd <= numel (circnums)
% 
%                 docircname(ii+design.yd,:) = [zeros(1, Inputs.NWindingLayers-1), -1];
% 
%             end
% 
%         end
% 
%     else
% 
%         for ii = 1:size (docircname,1)
% 
%             if ii <= numel (circnums)
% 
%                 docircname(ii,:) = [1, -ones(1, Inputs.NWindingLayers-1)];
% 
%             end
% 
%             if ii+design.yd <= numel (circnums)
% 
%                 docircname(ii+design.yd,:) = [zeros(1, Inputs.NWindingLayers-1), -1];
% 
%             end
% 
%         end
% 
%     end
%     
%     % rotate the specification to the desired starting point
%     docircname = circshift (docircname, [-(Inputs.StartSlot-1), 0]);
%     circnums = circshift (circnums, [-(Inputs.StartSlot-1), 0]);
% 
% %         circslotcount = 1;
% 
% %         slotnums = (1:Inputs.NSlots)';
% %         nextlayer = 1;
% %         layers = (1:Inputs.NWindingLayers)';
% 

    
    if Inputs.DrawCoilInsulation
    
       if strncmpi (Inputs.SimType, 'm', 1)
           [FemmProblem, matinds] = addmaterials_mfemm (FemmProblem, ...
                                                        {design.MagFEASimMaterials.CoilInsulation}, ...
                                                        'MaterialsLibrary', Inputs.MaterialsLibrary);
       elseif strncmpi (Inputs.SimType, 'h', 1)
           [FemmProblem, matinds] = addmaterials_mfemm (FemmProblem, ...
                                                        {design.HeatFEASimMaterials.CoilInsulation}, ...
                                                        'MaterialsLibrary', Inputs.MaterialsLibrary );
       end
    
        % add the coil insulation block labels
        coilinsBlockProps.BlockType = FemmProblem.Materials(matinds).Name;
        coilinsBlockProps.MaxArea = Inputs.CoilInsRegionMeshSize;
        coilinsBlockProps.InCircuit = '';
        coilinsBlockProps.InGroup = Inputs.CoilGroup;
    
        % add insulation labels if requested
    
        for indi = 1:size (inslabellocs)
            FemmProblem = addblocklabel_mfemm( FemmProblem, ...
                                               inslabellocs(indi,1), ...
                                               inslabellocs(indi,2), ...
                                               coilinsBlockProps );
        end
        
    end
        
    % shift all new nodes and block labels in X and Y if requested
    if XShift ~= 0 || YShift ~= 0
        
        newelcount = elementcount_mfemm (FemmProblem);
        
        nodeids = (elcount.NNodes):(newelcount.NNodes-1);
        
        FemmProblem = translatenodes_mfemm(FemmProblem, XShift, YShift, nodeids);
        
        blockids = (elcount.NBlockLabels):(newelcount.NBlockLabels-1);
                 
        FemmProblem = translateblocklabels_mfemm(FemmProblem, XShift, YShift, blockids);
        
    end
    

    for slotn = 1:Inputs.NSlots

        for layern = 1:Inputs.NWindingLayers

%             if Inputs.AddAllCoilsToCircuits || (k <= 2*design.Phases && docircname(k,n) ~= 0)
% 
%                 % only put the circuit in the first set of phase coils
%                 coilBlockProps.InCircuit = num2str(circnums(1));
%                 coilBlockProps.Turns = coilBlockProps.Turns * docircname(1,n);
% 
%             else
% 
%                 % only put the circuit in the first set of phase coils
%                 coilBlockProps.InCircuit = '';
% 
%             end 

            coilBlockProps.InCircuit = num2str(abs(design.WindingLayout.Phases(slotn,layern)));
            coilBlockProps.Turns = design.CoilTurns * sign (design.WindingLayout.Phases(slotn,layern));
            
            FemmProblem = addblocklabel_mfemm( FemmProblem, ...
                                               coillabellocs(row,1), ...
                                               coillabellocs(row,2), ...
                                               coilBlockProps);

%                 row = row + 1;
%             if row+(Inputs.NSlots*Inputs.NWindingLayers) <= size(coillabellocs,1)
%                 FemmProblem = addblocklabel_mfemm( FemmProblem, ...
%                                                    coillabellocs(row+(Inputs.NSlots*Inputs.NWindingLayers),1), ...
%                                                    coillabellocs(row,2), ...
%                                                    coilBlockProps );
%             end
%             
%             coilBlockProps.Turns = abs(design.CoilTurns);
%             coilBlockProps.InCircuit = '';
% 
            row = row + 1;

        end
%         
%         docircname = circshift (docircname, [-1, 0]);
%         circnums = circshift (circnums, [-1, 0]);

%             nextlayer = circshift(layers, -1);

%             nextlayer = nextlayer(1);

%             circslotcount = circslotcount + 1;

%             circnums = circshift(circnums, 1);

%             slotnums = circshift(slotnums, );

    end
    
end