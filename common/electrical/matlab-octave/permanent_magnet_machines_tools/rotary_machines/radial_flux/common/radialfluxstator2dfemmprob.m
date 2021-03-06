function [FemmProblem, info] = radialfluxstator2dfemmprob(slots, Poles, ryokecenter, thetapole, thetacoil, thetashoegap, ryoke, rcoil, rshoebase, rshoegap, drawnsides, varargin)
% creates a femm problem description of an radial flux toothed armature
%
% Syntax
%
% [FemmProblem, outernodes, coillabellocs] = ...
%           radialfluxinnerstator2dfemmprob(yokecentresep, slots, Poles, ...
%                 thetapole, thetacoil, thetashoegap, ryoke, rcoil, rshoebase, rshoegap, 'Parameter', Value)
%
% Input
%
%   yokecentresep - spacing between stator centres when drawing multiple
%     stators. Set to zero for a single stage machine.
%
%   slots - total number of slots in the machine
%
%   Poles - total number of Poles in the machine
%
%   ryokecenter - radial position of the centre of the stator yoke (radial
%     distance from the centre of the machine).
% 
%   thetapole - pole pitch in radians 
%
%   thetacoil - coil pitch in radians
%
%   thetashoegap - pitch of space between tooth shoes, i.e. the size of the
%     coil slot opening in the coil pitch direction. Measure in radians.
%
%   ryoke - radial length of the stator yoke on which the slots are mounted
%
%   rcoil - radial length of the coil in the slot, i.e. the slot depth
%
%   rshoebase - radial length of the tooth shoe at the point where it joins
%     the tooth.
%
%   rshoegap - radial length of the tooth shoe at it's tip at the slot
%     opening.
%
%   drawnsides - 2 element vector determining which sides of a stator are
%     drawn. If the first element evaluates to true, an internally facing
%     stator is drawn, if the second element evaluates to true and
%     externally facing stator is drawn.
%
% A number of parameter-value paris can also be supplied (in the form of a
% string and the corresponding value) to set various optional arguments. If
% not supplied these are given default values. The possible parameters are
% listed below:
%
%   'FemmProblem' - an existing mfemm FemmProblem structure to which the new
%     elements will be added. If not supplied a new problem is created.
% 
%   'NStators' - integer number of stators to be drawn in total. Defaults to
%     one. If more than one are to be drawn they will drawn with the center
%     fo each yoke separated by the value of yokecentresep
%
%   'NWindingLayers' - integer number of axial coil layers in the design.
%
%   'SlotMaterial' - index of the material in the FemmProblem.Materials
%     structure containing the material to be used for the slots/coils
%
%   'SlotRegionMeshSize' - Mesh size for the slot regions, usually the coil
%     cross-section. 
%
%   'ShoeGapMaterial' - index of the material in the FemmProblem.Materials
%    structure containing the material to be used for the gap between teeth
%    shoes when the teeth have a shoe which ends in a blunt edge.
%
%   'ShoeGapRegionMeshSize' - Mesh size for the gap between teeth shoes when
%     the teeth have a shoe which ends in a blunt edge.
%
%   'NSlots' - integer value determining the number of slots to be drawn. 
%     If not supplied enough slots will be drawn to fill two Poles of the
%     machine design. This options can be used to draw large or smaller
%     simulations of the same design.
%
%   'Tol' - tolerance at which to consider various dimensions to be zero,
%     by default this is 1e-5. This is used to prevent meshes occuring with
%     very large numbers of triangles.
%
%   'CoilBaseFraction' - scalar value indicating the starting point of 
%     curvature at the base of the slot (closest to the yoke). By default
%     the coil slot is given a curved base. This value indicates where the
%     curvature begins, specified as a fraction of the distance between the
%     yoke and the start of the base of any shoe (if present), or just the
%     top of the slot, if no shoe is present.
%
%   'DrawCoilInsulation' = true/false flag indicating whether to draw a
%     layer of coil insulation in the slot
%
%   'CoilInsulationThickness' - scalar value giving the thickness of the
%     coil insulation to draw when DrawCoilInsulation is true. Default is 0
%     if not supplied, so no coil insulation will actually be drawn unless
%     you explicitly set a value greater than zero.
%
%   'ShoeCurveControlFrac' - factor controlling the 'curvature' of the 
%     tooth shoe, this is a value between 0 and 1. The exact effect of this
%     number is complex, and depends on the geometry of the slot. However,
%     in general a lower number results in a curve closer to a line draw
%     directly from the shoe base to the shoe gap, while higher numbers
%     aproximate a sharp right angle. Anything in between will produce a
%     smooth curve. Defaults to 0.5.
%
%     N.B. the slot geometry affects this curve in the following way. If
%     the position of the shoe gap node is below the intercept of the line
%     formed by the edge of the slot and a vertical line at the shoe gap
%     node, the resulting curve will bend outward from the inside of the
%     slot. If the intercept is below the shoe gap node, the curve will
%     bend into the slot.
%
%  'SplitSlot' - true/false flag. If there is only two winding layers, the 
%    slot can be split into two in the circumferential direction rather
%    than the radial by setting this flag to true. Defaults to false. If
%    true coil label locations are provided in an anti-clockwise direction.
%
% Output
%
%   FemmProblem - An mfemm problem structure containing the new coil
%     elements.
%
%   outernodes - (NStators x 4) matrix containing the ids of the four outer
%     corner nodes of each drawn stator. The nodes are ordered in clockwise
%     direction starting from the bottom left corner node.
%
%   coillabellocs - (n * 2) matrix containing the x and y locations of the
%     coil labels. These are supplied for each stator part in sequence
%     moving from the left to right. 
%
%     [ 1st stator bottom slot outer coil layer x, 1st stator bottom left outer coil layer y ]
%     [ 1st stator bottom slot coil layer 2 x, 1st stator bottom left coil layer 2 y ]
%                                   .
%                                   . for NWindingLayers - 3 if more than 2
%                                   .
%     [ 1st stator bottom slot inner coil layer x, 1st stator bottom left inner coil layer y ]
%     [ 1st stator bottom left inner coil layer x, 1st stator bottom left inner coil layer y ]
%


    if numel(drawnsides) ~= 2
        error('drawnsides must be a two element vector.')
    end
    
    Inputs.NWindingLayers = 1;
    Inputs.SplitSlot = false;
    Inputs.FemmProblem = newproblem_mfemm('planar');
    Inputs.SlotMaterial = 1;
    Inputs.SlotRegionMeshSize = -1;
    Inputs.ShoeGapMaterial = 1;
    Inputs.ShoeGapRegionMeshSize = -1;
    Inputs.NSlots = [];
    Inputs.Tol = 1e-5;
    Inputs.DrawCoilInsulation = false;
    Inputs.CoilInsulationThickness = 0;
    Inputs.CoilBaseFraction = 0.05;
    Inputs.ShoeCurveControlFrac = 0.5;
    Inputs.XShift = 0;
    Inputs.YShift = 0;
    
    Inputs = parse_pv_pairs(Inputs, varargin);
    
    FemmProblem = Inputs.FemmProblem;
    
    elcount = elementcount_mfemm (FemmProblem);
    
    Inputs = rmfield(Inputs, 'FemmProblem');

    info.CoilLabelLocations = [];
    
    if drawnsides(1)

        % draw inner internally facing side
        [FemmProblem, outercornernodes, outercoillabellocs, info.InsulationLabelLocations] = ...
            radialfluxstatorhalf2dfemmprob(slots, Poles, thetapole, thetacoil, ...
                      thetashoegap, ryoke, rcoil, rshoebase, rshoegap, ...
                      ryokecenter, 'i', ...
                      'NWindingLayers', Inputs.NWindingLayers, ...
                      'FemmProblem', FemmProblem, ...
                      'ShoeGapMaterial', Inputs.ShoeGapMaterial, ...
                      'ShoeGapRegionMeshSize', Inputs.ShoeGapRegionMeshSize, ...
                      'Tol', Inputs.Tol, ... 
                      'NSlots', Inputs.NSlots, ...
                      'DrawCoilInsulation', Inputs.DrawCoilInsulation, ...
                      'CoilInsulationThickness', Inputs.CoilInsulationThickness, ...
                      'CoilBaseFraction', Inputs.CoilBaseFraction, ...
                      'SplitSlot', Inputs.SplitSlot);
    end
    
    if drawnsides(2)
        
        % draw outer externally facing side
        [FemmProblem, innercornernodes, innercoillabellocs, info.InsulationLabelLocations] = ...
            radialfluxstatorhalf2dfemmprob(slots, Poles, thetapole, thetacoil, ...
                      thetashoegap, ryoke, rcoil, rshoebase, rshoegap, ...
                      ryokecenter, 'o', ...
                      'NWindingLayers', Inputs.NWindingLayers, ...
                      'FemmProblem', FemmProblem, ...
                      'ShoeGapMaterial', Inputs.ShoeGapMaterial, ...
                      'ShoeGapRegionMeshSize', Inputs.ShoeGapRegionMeshSize, ...
                      'Tol', Inputs.Tol, ... 
                      'NSlots', Inputs.NSlots, ...
                      'DrawCoilInsulation', Inputs.DrawCoilInsulation, ...
                      'CoilInsulationThickness', Inputs.CoilInsulationThickness, ...
                      'CoilBaseFraction', Inputs.CoilBaseFraction, ...
                      'SplitSlot', Inputs.SplitSlot);

    end
    
    if drawnsides(1) && drawnsides(2)
        info.OuterNodes =  [innercornernodes(1), outercornernodes(2), outercornernodes(3), innercornernodes(4)];
        info.CoilLabelLocations = [innercoillabellocs; outercoillabellocs];
    elseif drawnsides(1)
        info.OuterNodes =  outercornernodes;
        info.CoilLabelLocations = outercoillabellocs;
    elseif drawnsides(2)
        info.OuterNodes =  innercornernodes;
        info.CoilLabelLocations = innercoillabellocs;
    else
        
    end
    
    % shift all new nodes and block labels in X and Y if requested
    if Inputs.XShift ~= 0 || Inputs.YShift ~= 0
        
        newelcount = elementcount_mfemm (FemmProblem);
        
        nodeids = (elcount.NNodes):(newelcount.NNodes-1);
        
        FemmProblem = translatenodes_mfemm(FemmProblem, Inputs.XShift, Inputs.YShift, nodeids);
        
        blockids = (elcount.NBlockLabels):(newelcount.NBlockLabels-1);
                 
        FemmProblem = translateblocklabels_mfemm(FemmProblem, Inputs.XShift, Inputs.YShift, blockids);
        
        info.CoilLabelLocations = bsxfun (@plus, info.CoilLabelLocations, [Inputs.XShift, Inputs.YShift]);
        
        if ~isempty (info.InsulationLabelLocations)
            info.InsulationLabelLocations = bsxfun (@plus, info.InsulationLabelLocations, [Inputs.XShift, Inputs.YShift]);
        end
        
    end
          
end
    

function FemmProblem = ax2rad(FemmProblem)

    for ind = 1:numel(FemmProblem.Nodes)
        [FemmProblem.Nodes(ind).Coords(1), FemmProblem.Nodes(ind).Coords(1)] = ...
            pol2cart(FemmProblem.Nodes(ind).Coords(2), FemmProblem.Nodes(ind).Coords(1));
    end
    
    for ind = 1:numel(FemmProblem.BlockLabels)
        FemmProblem.BlockLabels
    end

end
   

    
    