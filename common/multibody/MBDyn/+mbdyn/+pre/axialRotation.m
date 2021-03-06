classdef axialRotation < mbdyn.pre.twoNodeOffsetJoint
    
    properties
        
        angularVelocity;
        
    end
    
    methods
        
        function self = axialRotation (node1, node2, omega_drive, varargin)
            % constructor for axial rotation joint
            %
            % Syntax
            %
            % arj = mbdyn.pre.axialRotation (node1, node2, omega_drive)
            % arj = mbdyn.pre.axialRotation (..., 'Parameter', value)
            %
            % Description
            %
            % mbdyn.pre.axialRotation implements joint which forces two
            % nodes to rotate about relative axis 3 with imposed angular
            % velocity angular_velocity. This joint is equivalent to a
            % revolute hinge, but the angular velocity about axis 3 is
            % imposed by means of the driver.
            %
            % Input
            %
            %  node1 - mbdyn.pre.structuralNode (or derived class) object
            %    representing the first node the joint connects
            %
            %  node2 - mbdyn.pre.structuralNode (or derived class) object
            %    representing the second node the joint connects
            %
            %  omega_drive - mbdyn.pre.drive object, the driver which sets
            %    the angular velocity.
            %
            %
            % Additional arguments can be supplied as parameter-value
            % pairs. Available options are:
            %
            %
            %  'Offset1' - (3 x 1) vector containing the offset of the
            %    joint relative to the first node. To provide an
            %    alternative reference you can use the optional
            %    Offset1Reference parameter (see below)
            %
            %  'Offset2' - (3 x 1) vector containing the offset of the
            %    joint relative to the second node. To provide an
            %    alternative reference you can use the optional
            %    Offset1Reference parameter (see below)
            %
            %  'Offset1Reference' - by default the positions provided in
            %    position1 and position2 are relaive to the respective
            %    nodes in their reference frame. An alternative reference
            %    frame can be provided using this argument. Possible
            %    value for this are: 
            %      'node'          : the default behaviour
            %      'global'        : the global reference frame
            %      'other node'    : the frame of the other node the joint  
            %                        is attached to
            %      'other position': a relative position in the other 
            %                        node's reference frame, with respect 
            %                        to the relative position already 
            %                        specified for the other node
            %
            %  'Offset2Reference' - same as Offset1Reference, but for the
            %    second node
            %
            %  'RelativeOrientation1' - mbdyn.pre.orientmat object
            %    containing the orientation of the joint relative to the
            %    first node. To provide an alternative reference you can
            %    use the optional Orientation1Reference parameter (see
            %    below)
            %
            %  'RelativeOrientation2' - mbdyn.pre.orientmat object
            %    containing the orientation of the joint relative to the
            %    second node. To provide an alternative reference you can
            %    use the optional Orientation2Reference parameter (see
            %    below)
            %
            %  'Orientation1Reference' - string containing a reference for
            %    the orientation in RelativeOrientation1, can be one of
            %    'node', 'local' (equivalent to 'node'), 'other node',
            %    'other orientation' and 'global'. Defaut is 'node'. See
            %    Offset1Reference above for more information.
            %
            %  'Orientation2Reference' - string containing a reference for
            %    the orientation in RelativeOrientation2, can be one of
            %    'node', 'local' (equivalent to 'node'), 'other node',
            %    'other orientation' and 'global'. Defaut is 'node'. See
            %    Offset1Reference above for more information.
            %
            % Output
            %
            %  arj - mbdyn.pre.axialRotation object
            %
            %
            %
            % See Also: 
            %
            
            [ options, nopass_list ] = mbdyn.pre.axialRotation.defaultConstructorOptions ();
            
            options = parse_pv_pairs (options, varargin);
            
            pvpairs = mbdyn.pre.base.passThruPVPairs (options, nopass_list);
            
            % call the superclass constructor
            self = self@mbdyn.pre.twoNodeOffsetJoint (node1, node2, ...
                    'RelativeOffset1', options.Offset1, ...
                    'RelativeOffset2', options.Offset2, ...
                    pvpairs{:} );


            assert (isa (omega_drive, 'mbdyn.pre.drive'), ...
                'omega_drive must be an mbdyn.pre.drive' );
            
            self.angularVelocity = omega_drive;
            self.type = 'axial rotation';
            
            
        end
        
        function str = generateMBDynInputString (self)
            % generates MBDyn input string for axialRotation joint
            % 
            % Syntax
            %  
            % str = generateMBDynInputString (arj)
            %  
            % Description
            %  
            % generateMBDynInputString is a method shared by all MBDyn
            % components and is called to generate a character vector used
            % to construct an MBDyn input file.
            %  
            % Input
            %  
            %  arj - mbdyn.pre.axialRotation object
            %  
            % Output
            %  
            %  str - character vector for insertion into an MBDyn input
            %   file.
            %
            
            str = generateMBDynInputString@mbdyn.pre.twoNodeOffsetJoint (self, true);
            
            str = self.addOutputLine (str, self.angularVelocity.generateMBDynInputString (), 2, false);
            
            str = self.addOutputLine (str, ';', 1, false, sprintf('end %s', self.type));
            
        end
        
    end
    
    methods (Static)
        
        function [ options, nopass_list ] = defaultConstructorOptions ()
            
            options = mbdyn.pre.twoNodeOffsetJoint.defaultConstructorOptions ();
            
            parentfnames = fieldnames (options);
            
            options.Offset1 = [];
            options.Offset2 = [];
            
            allfnames = fieldnames (options);
            
            newnames = setdiff (allfnames, parentfnames);
            
            nopass_list = [ newnames; 
                            { 'RelativeOffset1'; ...
                              'RelativeOffset2' }; ...
                          ];
            
        end
        
    end
    
end