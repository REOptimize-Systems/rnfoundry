function [magLxyCoords, magangle] = drawsquaremags(magMesh, FxyCoords, Taup, Taum, pos, magname, maggroup)

    if nargin < 6
        magname = 'NdFeB 40 MGOe';
    end
    
    if nargin < 7
        maggroup = 0;
    end
    
    % Create magnet label structures for left and right polarity magnets
    % respectively, initially magnets of field and armature will oppose
    % each other
   
    blockPropStructArray = [mi_blockpropstruct(1, magname, 0, magMesh, maggroup, '', 0, 0), ...
                            mi_blockpropstruct(1, magname, 0, magMesh, maggroup, '', 0, 180)];
    % First define the coordinates at position pos = 0;
    
    % Map coordinates onto cylinder surface
    FxyCoords(:,2) = FxyCoords(:,2) .* pi ./ Taup;
    
    pos = pos .* pi ./ Taup;
    
    % rotate around cylinder
    FxyCoords(:,2) = rem(FxyCoords(:,2) + pos, 2*pi);
    
    % negative coordinates imply they are in fact rotated backwards which
    % we will take to be positions relative to the top of the sim
    FxyCoords(sign(FxyCoords(:,2)) == -1, 2) = (2*pi) + FxyCoords(sign(FxyCoords(:,2)) == -1, 2); 
    
    % Map back to x-y plane
    FxyCoords(:,2) = Taup .* FxyCoords(:,2) ./ pi;

    minsizes = max(Taum * 0.0005, 1e-5);
    
    if abs(FxyCoords(1,2)) <= minsizes || abs(((2*Taup) - abs(FxyCoords(1,2)))) <= minsizes
        % The bottom of the bottom magnet is against the base of the sim
        % (or at least within 1e-5 m of it (0.01 mm)
        % Draw line 3--4 and join up nodes to base then draw top mag
        % rectangle, link nodes 4-6 and 8-top
        for n = 3:4
            mi_addnode(FxyCoords(n,1), FxyCoords(n,2));
        end

        mi_drawrectangle(FxyCoords(5,1),FxyCoords(5,2),FxyCoords(8,1),FxyCoords(8,2));

        segPropStructArray = mi_segpropstruct(5, 0);

        mi_addsegment2([FxyCoords(3,1),...
            FxyCoords(3,1),...
            FxyCoords(4,1),...
            FxyCoords(4,1),...
            FxyCoords(8,1)],...
            [FxyCoords(3,2),...
            FxyCoords(3,2),...
            FxyCoords(4,2),...
            FxyCoords(4,2),...
            FxyCoords(8,2)],...
            [FxyCoords(3,1),...
            FxyCoords(4,1),...
            FxyCoords(4,1),...
            FxyCoords(6,1),...
            FxyCoords(8,1)],...
            [0,...
            FxyCoords(4,2),...
            0,...
            FxyCoords(6,2),...
            2*Taup], segPropStructArray);
        % Now draw labels
        magLxyCoords = rectcentre([FxyCoords(1,1); FxyCoords(5,1)], [0; FxyCoords(5,2)], [FxyCoords(4,1); FxyCoords(8,1)], [FxyCoords(4,2);FxyCoords(8,2)]);
        mi_addblocklabel2(magLxyCoords, blockPropStructArray);
        magangle = [0, 180];
        
    elseif abs(FxyCoords(3,2)) <= minsizes || abs(((2*Taup) - abs(FxyCoords(3,2)))) <= minsizes
        % The top of the bottom magnet is against the base of the sim
        % (or at least within 1e-4 m of it (0.1 mm), or equivalently, the
        % top of the top magnet is against the top of the sim
        % Draw line 1--2 and join up nodes to top then draw top mag
        % rectangle, link nodes 8-2 and 6-bot
        for n = 1:2
            mi_addnode(FxyCoords(n,1), FxyCoords(n,2));
        end

        mi_drawrectangle(FxyCoords(5,1),FxyCoords(5,2),FxyCoords(8,1),FxyCoords(8,2));

        segPropStructArray = mi_segpropstruct(5, 0);

        mi_addsegment2([FxyCoords(1,1),...
            FxyCoords(1,1),...
            FxyCoords(2,1),...
            FxyCoords(8,1),...
            FxyCoords(6,1)],...
            [FxyCoords(1,2),...
            FxyCoords(1,2),...
            FxyCoords(2,2),...
            FxyCoords(8,2),...
            FxyCoords(6,2)],...
            [FxyCoords(2,1),...
            FxyCoords(1,1),...
            FxyCoords(2,1),...
            FxyCoords(2,1),...
            FxyCoords(6,1)],...
            [FxyCoords(2,2),...
            2*Taup,...
            2*Taup,...
            FxyCoords(2,2),...
            0], segPropStructArray);

        % Now draw labels
        magLxyCoords = rectcentre([FxyCoords(1,1); FxyCoords(5,1)], [FxyCoords(1,2); FxyCoords(5,2)], [FxyCoords(2,1); FxyCoords(8,1)], [2*Taup; FxyCoords(8,2)]);
        mi_addblocklabel2(magLxyCoords, blockPropStructArray);
        magangle = [0, 180];
        
    elseif abs(FxyCoords(5,2)) <= minsizes || abs(((2*Taup) - abs(FxyCoords(5,2)))) <= minsizes
        % The bottom of the top magnet is against the base of the sim
        % (or at least within 1e-4 m of it (0.1 mm)
        % Draw line 7--8 and join up nodes to base then draw bottom mag
        % rectangle, link nodes 8-2 and 4-top
        for n = 7:8
            mi_addnode(FxyCoords(n,1), FxyCoords(n,2));
        end

        mi_drawrectangle(FxyCoords(1,1),FxyCoords(1,2),FxyCoords(4,1),FxyCoords(4,2));

        segPropStructArray = mi_segpropstruct(5, 0);

        mi_addsegment2([FxyCoords(7,1),...
            FxyCoords(8,1),...
            FxyCoords(7,1),...
            FxyCoords(8,1),...
            FxyCoords(4,1)],...
            [FxyCoords(7,2),...
            FxyCoords(8,2),...
            FxyCoords(7,2),...
            FxyCoords(8,2),...
            FxyCoords(4,2)],...
            [FxyCoords(7,1),...
            FxyCoords(8,1),...
            FxyCoords(8,1),...
            FxyCoords(2,1),...
            FxyCoords(4,1)],...
            [0,...
            0,...
            FxyCoords(8,2),...
            FxyCoords(2,2),...
            2*Taup], segPropStructArray);

        % Now draw labels
        magLxyCoords = rectcentre([FxyCoords(1,1); FxyCoords(5,1)], [FxyCoords(1,2); 0], [FxyCoords(4,1); FxyCoords(8,1)], [FxyCoords(4,2);FxyCoords(8,2)]);
        mi_addblocklabel2(magLxyCoords, blockPropStructArray);
        magangle = [0, 180];
        
    elseif abs(FxyCoords(7,2)) <= minsizes || abs(((2*Taup) - abs(FxyCoords(7,2)))) <= minsizes
        % The top of the top magnet is against the base of the sim
        % (or at least within 1e-4 m of it (0.1 mm)
        % Draw line 5--6 and join up nodes to top then draw bottom mag
        % rectangle, link nodes 4-6 and 2-bot
        for n = 5:6
            mi_addnode(FxyCoords(n,1), FxyCoords(n,2));
        end

        mi_drawrectangle(FxyCoords(1,1),FxyCoords(1,2),FxyCoords(4,1),FxyCoords(4,2));

        segPropStructArray = mi_segpropstruct(5, 0);

        mi_addsegment2([FxyCoords(5,1),...
            FxyCoords(5,1),...
            FxyCoords(6,1),...
            FxyCoords(4,1),...
            FxyCoords(2,1)],...
            [FxyCoords(5,2),...
            FxyCoords(5,2),...
            FxyCoords(6,2),...
            FxyCoords(4,2),...
            FxyCoords(2,2)],...
            [FxyCoords(6,1),...
            FxyCoords(5,1),...
            FxyCoords(6,1),...
            FxyCoords(6,1),...
            FxyCoords(2,1)],...
            [FxyCoords(6,2),...
            2*Taup,...
            2*Taup,...
            FxyCoords(6,2),...
            0], segPropStructArray);

        % Now draw labels
        magLxyCoords = rectcentre([FxyCoords(1,1); FxyCoords(5,1)], [FxyCoords(1,2); FxyCoords(5,2)], [FxyCoords(4,1); FxyCoords(8,1)], [FxyCoords(4,2); 2*Taup]);
        mi_addblocklabel2(magLxyCoords, blockPropStructArray);
        magangle = [0, 180];
        
    elseif FxyCoords(3,2) < FxyCoords(1,2)
        % Draw line 1--2 and join up nodes to top then draw line 3--4 and
        % join up nodes to base, then draw top mag rectangle, link nodes
        % 4-6 and 8-2
        for n = 1:4
            mi_addnode(FxyCoords(n,1), FxyCoords(n,2));
        end

        mi_drawrectangle(FxyCoords(5,1),FxyCoords(5,2),FxyCoords(8,1),FxyCoords(8,2));

        segPropStructArray = mi_segpropstruct(8, 0);

        mi_addsegment2([FxyCoords(1,1),...
            FxyCoords(1,1),...
            FxyCoords(2,1),...
            FxyCoords(3,1),...
            FxyCoords(3,1),...
            FxyCoords(4,1),...
            FxyCoords(8,1),...
            FxyCoords(4,1)],...
            [FxyCoords(1,2),...
            FxyCoords(1,2),...
            FxyCoords(2,2),...
            FxyCoords(3,2),...
            FxyCoords(3,2),...
            FxyCoords(4,2),...
            FxyCoords(8,2),...
            FxyCoords(4,2)],...
            [FxyCoords(2,1),...
            FxyCoords(1,1),...
            FxyCoords(2,1),...
            FxyCoords(4,1),...
            FxyCoords(3,1),...
            FxyCoords(4,1),...
            FxyCoords(2,1),...
            FxyCoords(6,1)],...
            [FxyCoords(2,2),...
            2*Taup,...
            2*Taup,...
            FxyCoords(4,2),...
            0,...
            0,...
            FxyCoords(2,2),...
            FxyCoords(6,2)], segPropStructArray);

        % Now draw labels
        magLxyCoords(1,:) = rectcentre(FxyCoords(5,1), FxyCoords(5,2), FxyCoords(8,1), FxyCoords(8,2));
        mi_addblocklabel2(magLxyCoords(1,:), blockPropStructArray(2));

        magLxyCoords(2,:) = rectcentre(FxyCoords(1,1), FxyCoords(1,2), FxyCoords(4,1), 2*Taup);
        mi_addblocklabel2(magLxyCoords(2,:), blockPropStructArray(1));

        magLxyCoords(3,:) = rectcentre(FxyCoords(3,1), FxyCoords(3,2), FxyCoords(4,1), 0);
        mi_addblocklabel2(magLxyCoords(3,:), blockPropStructArray(1));

        magangle = [180, 0, 0];
        
    elseif FxyCoords(7,2) < FxyCoords(5,2)
        % Draw line 7--8 and join up nodes to base then draw line 5--6 and
        % join up nodes to top, then draw bottom mag rectangle, link nodes
        % 4-6 and 8-2
        for n = 5:8
            mi_addnode(FxyCoords(n,1), FxyCoords(n,2));
        end

        mi_drawrectangle(FxyCoords(1,1),FxyCoords(1,2),FxyCoords(4,1),FxyCoords(4,2));

        segPropStructArray = mi_segpropstruct(8, 0);

        mi_addsegment2([FxyCoords(5,1),...
            FxyCoords(5,1),...
            FxyCoords(6,1),...
            FxyCoords(7,1),...
            FxyCoords(7,1),...
            FxyCoords(8,1),...
            FxyCoords(4,1),...
            FxyCoords(8,1)],...
            [FxyCoords(5,2),...
            FxyCoords(5,2),...
            FxyCoords(6,2),...
            FxyCoords(7,2),...
            FxyCoords(7,2),...
            FxyCoords(8,2),...
            FxyCoords(4,2),...
            FxyCoords(8,2)],...
            [FxyCoords(6,1),...
            FxyCoords(5,1),...
            FxyCoords(6,1),...
            FxyCoords(8,1),...
            FxyCoords(7,1),...
            FxyCoords(8,1),...
            FxyCoords(6,1),...
            FxyCoords(2,1)],...
            [FxyCoords(6,2),...
            2*Taup,...
            2*Taup,...
            FxyCoords(8,2),...
            0,...
            0,...
            FxyCoords(6,2),...
            FxyCoords(2,2)], segPropStructArray);

        % Now draw labels
        magLxyCoords(1,:) = rectcentre(FxyCoords(5,1), FxyCoords(5,2), FxyCoords(6,1), 2*Taup);
        mi_addblocklabel2(magLxyCoords(1,:), blockPropStructArray(2));

        magLxyCoords(2,:) = rectcentre(FxyCoords(7,1), FxyCoords(7,2), FxyCoords(8,1), 0);
        mi_addblocklabel2(magLxyCoords(2,:), blockPropStructArray(2));

        magLxyCoords(3,:) = rectcentre(FxyCoords(1,1), FxyCoords(1,2), FxyCoords(4,1), FxyCoords(4,2));
        mi_addblocklabel2(magLxyCoords(3,:), blockPropStructArray(1));

        magangle = [180, 180, 0];
        
    elseif FxyCoords(1,2) < FxyCoords(3,2) && FxyCoords(5,2) < FxyCoords(7,2) && FxyCoords(5,2) > FxyCoords(1,2)
        % Draw both rectangles, bottom mag at bottom and top mag at top
        % then link nodes 4-6 and 8-top and 2-bot

        mi_drawrectangle(FxyCoords(1,1),FxyCoords(1,2),FxyCoords(4,1),FxyCoords(4,2));
        mi_drawrectangle(FxyCoords(5,1),FxyCoords(5,2),FxyCoords(8,1),FxyCoords(8,2));

        segPropStructArray = mi_segpropstruct(8, 0);

        mi_addsegment2([FxyCoords(4,1),...
            FxyCoords(8,1),...
            FxyCoords(2,1)],...
            [FxyCoords(4,2),...
            FxyCoords(8,2),...
            FxyCoords(2,2)],...
            [FxyCoords(6,1),...
            FxyCoords(8,1),...
            FxyCoords(2,1)],...
            [FxyCoords(6,2),...
            2*Taup,...
            0], segPropStructArray);

        % Now draw labels
        magLxyCoords = rectcentre([FxyCoords(1,1); FxyCoords(5,1)], ...
                                  [FxyCoords(1,2); FxyCoords(5,2)], ...
                                  [FxyCoords(4,1); FxyCoords(8,1)], ...
                                  [FxyCoords(4,2); FxyCoords(8,2)]);
                              
        mi_addblocklabel2(magLxyCoords, blockPropStructArray);

        magangle = [0, 180];
        
    elseif FxyCoords(1,2) < FxyCoords(3,2) && FxyCoords(5,2) < FxyCoords(7,2) && FxyCoords(5,2) < FxyCoords(1,2)
        % Draw both rectangles, bottom mag at top and top mag at bottom
        % then link nodes 2-8 and 4-top and 6-bot

        mi_drawrectangle(FxyCoords(1,1),FxyCoords(1,2),FxyCoords(4,1),FxyCoords(4,2));
        mi_drawrectangle(FxyCoords(5,1),FxyCoords(5,2),FxyCoords(8,1),FxyCoords(8,2));
        mi_addsegment2([FxyCoords(2,:), FxyCoords(8,:); FxyCoords(4,:),  FxyCoords(4,1), 2*Taup; FxyCoords(6,:),  FxyCoords(6,1), 0])

        % Now draw labels
        magLxyCoords = rectcentre([FxyCoords(1,1); FxyCoords(5,1)], [FxyCoords(1,2); FxyCoords(5,2)], [FxyCoords(4,1); FxyCoords(8,1)], [FxyCoords(4,2); FxyCoords(8,2)]);
        mi_addblocklabel2(magLxyCoords, blockPropStructArray);

        magangle = [0, 180];
        
    end

    
    
end