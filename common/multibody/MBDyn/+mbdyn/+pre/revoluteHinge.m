classdef revoluteHinge < mbdyn.pre.twoNodeOffsetJoint
    
    
    properties (GetAccess = public, SetAccess = protected)
        frictionRadius;
        frictionModel;
        frictionShapeFcn;
        preload;
    end
    
    methods
        
        function self = revoluteHinge (node1, node2, position1, position2, varargin)
            % revoluteHinge constructor
            %
            % Syntax
            %
            %  rh = revoluteHinge (node1, node2, position1, position2)
            %  rh = revoluteHinge (..., 'Parameter', value)
            %
            % Input
            %
            %  node1 - mbdyn.pre.structuralNode (or derived class) object
            %    representing to first node the joint connects
            %
            %  node2 - mbdyn.pre.structuralNode (or derived class) object
            %    representing to second node the joint connects
            %
            %  position1 - (3 x 1) vector containing the offset of the
            %    joint relative to the first node. To provide an
            %    alternative reference you can use the optional
            %    Offset1Reference parameter (see below)
            %
            %  position2 - (3 x 1) vector containing the offset of the
            %    joint relative to the second node. To provide an
            %    alternative reference you can use the optional
            %    Offset1Reference parameter (see below)
            %
            % Additional arguments can be supplied as parameter-value
            % pairs. Available options are:
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
            %  'InitialTheta' - 
            %
            %  'FrictionRadius' - Supplying this value indicates that a
            %    friction model is to be applied to the joint. If supplying
            %    this, you must also supply the 'FrictionModel' and
            %    'ShapeFunction' options, and may also optionally supply
            %    the 'Preload' option. The friction radius is the average
            %    radius at which to apply friction.
            %
            %  'FrictionModel' - 
            %
            %  'Preload' - 
            %
            %  'ShapeFunction' - 
            %  
            % Output
            %
            %  rh - mbdyn.pre.revoluteHinge object
            %
            %
            
            [ options, nopass_list ] = mbdyn.pre.revoluteHinge.defaultConstructorOptions ();
            
            options = parse_pv_pairs (options, varargin);
            
            pvpairs = mbdyn.pre.base.passThruPVPairs ( options, nopass_list);
            
            % call the superclass constructor
            self = self@mbdyn.pre.twoNodeOffsetJoint (node1, node2, ...
                        'RelativeOffset1', position1, ...
                        'RelativeOffset2', position2, ...
                        pvpairs{:} );
            
            if ~isempty (options.FrictionRadius)
                if isempty (options.FrictionModel)
                    error ('If supplying a friction radius, you must also supply a friction model (FrictionModel option)');
                end
                self.checkNumericScalar (options.FrictionRadius, true, 'FrictionRadius')
                
                if isempty (options.ShapeFunction)
                    error ('If supplying a friction radius, you must also supply a friction shape function (ShapeFunction option)');
                end
                
                if ~isempty (options.Preload)
                    self.checkNumericScalar (options.Preload, true, 'Preload');
                    self.preload = options.Preload;
                end
            end
            
            if ~isempty (options.FrictionModel)
                if isempty (options.FrictionRadius)
                    error ('If supplying a friction model, you must also supply a friction radius (FrictionRadius option)');
                end
                assert (isa (options.FrictionModel, 'mbdyn.pre.frictionModel'), ...
                    'Supplied FrictionModel is not an mbdyn.pre.frictionModel object (or derived class)');
            end
            
            self.frictionRadius = options.FrictionRadius;
            self.frictionModel = options.FrictionModel;
            self.frictionShapeFcn = options.ShapeFunction;
            
            self.type = 'revolute hinge';
            
        end
        
        function str = generateMBDynInputString (self)
            % generates MBDyn input string for revoluteHinge joint
            % 
            % Syntax
            %  
            % str = generateMBDynInputString (rh)
            %  
            % Description
            %  
            % generateMBDynInputString is a method shared by all MBDyn
            % components and is called to generate a character vector used
            % to construct an MBDyn input file.
            %  
            % Input
            %  
            %  rh - mbdyn.pre.revoluteHinge object
            %  
            % Output
            %  
            %  str - character vector for insertion into an MBDyn input
            %   file.
            %

            addcomma = ~isempty (self.frictionRadius);

            str = generateMBDynInputString@mbdyn.pre.twoNodeOffsetJoint (self, addcomma);
            
            if ~isempty (self.frictionRadius)
                str = self.addOutputLine (str, self.commaSepList ('friction', self.frictionRadius), 3, true, 'friction radius');
                
                if ~isempty (self.preload)
                    str = self.addOutputLine (str, self.commaSepList ('preload', self.preload), 4, true, 'friction preload');
                end
                
                str = self.addOutputLine (str, self.frictionModel.generateMBDynInputString (), 4, true, 'friction model');
                
                str = self.addOutputLine (str, self.frictionShapeFcn.generateMBDynInputString (), 4, false, 'friction shape function');
            end
            
            str = self.addOutputLine (str, ';', 1, false, sprintf('end %s', self.type));
            
            str = self.addRegularization (str);
            
        end
        
        function draw (self, varargin)
            
            options.AxesHandle = [];
            options.ForceRedraw = false;
            options.Mode = 'solid';
            
            options = parse_pv_pairs (options, varargin);
            
%             draw@mbdyn.pre.twoNodeOffsetJoint ( self, ...
%                 'AxesHandle', options.AxesHandle, ...
%                 'ForceRedraw', options.ForceRedraw, ...
%                 'Mode', options.Mode );

            if options.ForceRedraw
                self.needsRedraw = true;
            end
            
            self.checkAxes (options.AxesHandle);
            
            node1pos = self.node1.absolutePosition;
            jref = self.reference ();
            jpos = jref.pos ();
            node2pos = self.node2.absolutePosition;
                
            if ~self.needsRedraw
                % always have to redraw the line connecting the two points.
                % This changes shape, so we can't just transform the line
                % object
                delete (self.shapeObjects{1})
                self.shapeObjects{1} =  line ( self.drawAxesH, ...
                                               [ node1pos(1), jpos(1), node2pos(1) ], ...
                                               [ node1pos(2), jpos(2), node2pos(2) ], ...
                                               [ node1pos(3), jpos(3), node2pos(3) ], ...
                                               'Color', self.drawColour );
                                       
            end
            
            if isempty (self.shapeObjects) ...
                    || self.needsRedraw
                % a full redraw is needed (and not just a modification of
                % transform matrices for the objects).
                
                % delete the current patch object
                self.deleteAllDrawnObjects ();
                
                self.shapeObjects = { line( self.drawAxesH, ...
                                            [ node1pos(1), jpos(1), node2pos(1) ], ...
                                            [ node1pos(2), jpos(2), node2pos(2) ], ...
                                            [ node1pos(3), jpos(3), node2pos(3) ], ...
                                            'Color', self.drawColour ), ...
                                      line( self.drawAxesH, ...
                                            [ 0, 0 ], ...
                                            [ 0, 0 ], ...
                                            [ -self.shapeParameters(1)/2, self.shapeParameters(3)/2 ], ...
                                            'Parent', self.transformObject, ...
                                            'Color', self.drawColour, ...
                                            'LineStyle', '--' )
                                    };
                
                self.needsRedraw = false;

%                 if options.Light
%                     light (self.drawAxesH);
%                 end
                
            end
            
            self.setTransform ();

%             self.setTransform ();
            
        end
        
    end
    
    methods (Access = protected)
        
%         function setTransform (self)
%             
%             om = self.absoluteJointOrientation;
%             
%             M = [ om.orientationMatrix, self.absoluteJointPosition; ...
%                   0, 0, 0, 1 ];
%                   
%             set ( self.transformObject, 'Matrix', M );
%             
%         end
        
    end
    
    methods (Static)
        
        function [ options, nopass_list ] = defaultConstructorOptions ()
            
            options = mbdyn.pre.twoNodeOffsetJoint.defaultConstructorOptions ();
            
            parentfnames = fieldnames (options);
            
            % add default options common to all revoluteHinge objects
            options.InitialTheta = [];
            options.FrictionRadius = [];
            options.FrictionModel = [];
            options.Preload = [];
            options.ShapeFunction = [];
            
            allfnames = fieldnames (options);
            
            C = setdiff (allfnames, parentfnames);
            
            nopass_list = [ { 'RelativeOffset1'; ...
                              'RelativeOffset2' }; ...
                            C ];
            
        end
        
    end
    
end