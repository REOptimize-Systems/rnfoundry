function total_joint = pinOneNode (node, varargin)
% clamp one node in its initial global position and orientation
%
% Syntax
%
%  total_joint = pinOneNode (node1, node2)
%
% Description
%
% pinOneNode is a convenience function which creates a total pin joint
% which clamps a node in it's initial global position and orientation.
%
% Input
%
%  node - mbdyn.pre.structuralNode (or derived class) object
%    representing the node the joint connects
%
% Output
%
%  total_joint - mbdyn.pre.totalJoint object with all position and 
%   orientation constraints active and set to keep the initial relative
%   position and orientation of the input node.
%
%

    options.ClampX = true;
    options.ClampY = true;
    options.ClampZ = true;
    options.ClampRotX = true;
    options.ClampRotY = true;
    options.ClampRotZ = true;
    options.Name = '';
    
    options = parse_pv_pairs (options, varargin);
    
    drv_position = mbdyn.pre.componentTplDriveCaller ( { mbdyn.pre.const(node.absolutePosition(1)), ...
                                                         mbdyn.pre.const(node.absolutePosition(2)), ...
                                                         mbdyn.pre.const(node.absolutePosition(3)) } );
                                                     
% 	euler_vector = orient2euler123 (node.absoluteOrientation.orientationMatrix);
    
    euler_vector = SpinCalc('DCMtoEV', node.absoluteOrientation.orientationMatrix, 1e-6, 0);
    
    euler_vector = euler_vector(1:3) * deg2rad (euler_vector(4));
    
	drv_orientation = mbdyn.pre.componentTplDriveCaller ( { mbdyn.pre.const(euler_vector(1)), ...
                                                            mbdyn.pre.const(euler_vector(2)), ...
                                                            mbdyn.pre.const(euler_vector(3)) } );
    
    total_joint = mbdyn.pre.totalPin ( node, ...
                                       'PositionStatus', [options.ClampX, options.ClampY, options.ClampZ], ...
                                       'OrientationStatus', [options.ClampRotX, options.ClampRotY, options.ClampRotZ], ...
                                       'RelativeOffset', 'null', ...
                                       'RelativeOffsetReference', 'node', ...
                                       'AbsolutePosition', 'null', ...
                                       'AbsolutePositionReference', 'node', ...
                                       'ImposedAbsolutePosition', drv_position, ...
                                       'RelativeRotOrientation', eye(3), ...
                                       'RelativeRotOrientationReference', 'node', ...
                                       'ImposedAbsoluteRotation', drv_orientation, ...
                                       'Name', options.Name );

end