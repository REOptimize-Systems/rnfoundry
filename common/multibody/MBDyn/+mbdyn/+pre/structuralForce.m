classdef structuralForce < mbdyn.pre.force
% Applies a force to a structural node
%
% Syntax
%
% sf = mbdyn.pre.structuralForce (node, force_type, force_value)
% sf = mbdyn.pre.structuralForce (..., 'Parameter', value)
%
% Description
%
% Applies a force to a structural node.
%
% mbdyn.pre.structuralForce Methods:
%
%   structuralForce - mbdyn.pre.structuralForce constructor
%   generateMBDynInputString - generates MBDyn input string for a mbdyn.pre.structuralForce
%
%
% See Also: mbdyn.pre.structuralCouple, mbdyn.pre.structuralInternalForce
%
%

    properties (GetAccess = public, SetAccess = protected)
        
        position;
        positionReference;
        node;
        forceType;
        forceValue;
        moment;
        forceOrientation;
        momentOrientation;
        forceOrientationReference;
        momentOrientationReference;
        
    end
    
    methods
        
        function self = structuralForce (node, force_type, force_value, varargin)
            % mbdyn.pre.structuralForce constructor
            %
            % Syntax
            %
            % sf = mbdyn.pre.structuralForce (node, force_type, force_value)
            % sf = mbdyn.pre.structuralForce (..., 'Parameter', value)
            %
            % Description
            %
            % Applies a force to a structural node.
            %
            % Input
            %
            %  node - mbdyn.pre.structuralNode object defining the
            %   structural node to which the force is applied.
            %
            %  force_type - string containing the type of force element.
            %   Can be 'absolute', 'follower' or 'total'. The absolute
            %   force has the force defined in the global frame wheras the
            %   follower force is defined in the reference frame of the
            %   node. The total force is intrinsically follower.
            %
            %  force_value - either a simple three element column vector of 
            %   constant forces to apply, or an
            %   mbdyn.pre.componentTplDriveCaller object with 3 components
            %   defining the force applied to the node. If a vector is
            %   supplied this is internally converted to a
            %   mbdyn.pre.componentTplDriveCaller object with three
            %   mbdyn.pre.const drives.
            %
            % Additional arguments may be provided as parameter-value
            % pairs. Some are mandetory depending on the force_type value.
            % The available options are:
            %
            % 'Position' - (3 x 1) vector defining the offset with respect
            %   to the node of the point where the force is applied. It is
            %   mandatory for the 'absolute' and 'follower' force type.
            %
            % 'PositionReference' - optional string giving the reference
            %   for the position, can be 'global', 'local' or 'node'.
            %   Default is 'node' if not supplied.
            %
            % Output
            %
            %  sf - mbdyn.pre.structuralForce object
            %
            %
            %
            % See Also: 
            %
            
            [ options, nopass_list ] = mbdyn.pre.structuralForce.defaultConstructorOptions ();
            
            options = parse_pv_pairs (options, varargin);
            
            pvpairs = mbdyn.pre.base.passThruPVPairs ( options, nopass_list);
            
            % call the superclass constructor
            self = self@mbdyn.pre.force (pvpairs{:});
            
            self.checkIsStructuralNode (node, true);
            self.checkAllowedStringInputs (force_type, {'absolute', 'follower', 'total'}, true, 'force_type');
            self.checkAllowedStringInputs (options.PositionReference, {'global', 'local', 'node'}, true, 'PositionReference');
            
            
            switch force_type
                
                case {'absolute', 'follower'}
                    
                    assert (~isempty (options.Position), ...
                        'You must supply a Position for the absolute and follower force types');
                    
                    assert (~isempty (force_value), ...
                        'You must supply a force_value for the absolute and follower force types');
                    
                    if self.checkCartesianVector (force_value, false, 'force_value')
                        
                        force_val_vec = force_value;
                        
                        force_value = mbdyn.pre.componentTplDriveCaller ( { ...
                                                mbdyn.pre.const(force_val_vec(1)), ...
                                                mbdyn.pre.const(force_val_vec(2)), ...
                                                mbdyn.pre.const(force_val_vec(3)) } );
                        
                    elseif self.checkTplDriveCaller (force_value, false, 'force_value')
                        % do nothing
                    else
                        error ('force_value must be a 3 element cartesian vector or a mbdyn.pre.componentTplDriveCaller object.');
                    end
                    self.checkCartesianVector (options.Position, true, 'Position');
                    
                    % ensure everything else is ignored
                    options.ForceOrientation = [];
                    options.ForceOrientationReference = 'node';
                    options.MomentValue = [];
                    options.MomentOrientation = [];
                    options.MomentOrientationReference = 'node';

                case 'total'
                    
                    self.emptyOrCheck (@self.checkTplDriveCaller, force_value, true, 'force_value')
                    self.emptyOrCheck (@self.checkOrientationMatrix, options.ForceOrientation, true, 'ForceOrientation')
                    self.checkAllowedStringInputs (options.ForceOrientationReference, {'global', 'local', 'node'}, true, 'ForceOrientationReference');
                    self.emptyOrCheck (@self.checkCartesianVector, options.Position, true, 'Position')
                    self.emptyOrCheck (@self.checkTplDriveCaller, options.MomentValue, true, 'MomentValue')
                    self.emptyOrCheck (@self.checkOrientationMatrix, options.MomentOrientation, true, 'MomentOrientation')
                    self.checkAllowedStringInputs (options.MomentOrientationReference, {'global', 'local', 'node'}, true, 'MomentOrientationReference');
                    
                    
                otherwise
                        
            end
            
            self.subType = 'structural';
            self.forceValue = force_value;
            self.moment = options.MomentValue;
            self.forceType = force_type;
            self.node = node;
            self.position = options.Position;
            self.positionReference = options.PositionReference;
            
            self.momentOrientation = options.MomentOrientation;
            self.momentOrientationReference =  options.MomentOrientationReference;
            self.forceOrientation = options.ForceOrientation;
            self.forceOrientationReference = options.ForceOrientationReference;
            
        end
        
        function str = generateMBDynInputString (self)
            % generates MBDyn input string for a mbdyn.pre.structuralForce
            % 
            % Syntax
            %  
            % str = generateMBDynInputString (sf)
            %  
            % Description
            %  
            % generateMBDynInputString is a method shared by all MBDyn
            % components and is called to generate a character vector used
            % to construct an MBDyn input file.
            %  
            % Input
            %  
            %  sf - mbdyn.pre.structuralForce object
            %  
            % Output
            %  
            %  str - character vector for insertion into an MBDyn input
            %   file.
            %
            
            str = generateMBDynInputString@mbdyn.pre.force(self);
            
            str = self.addOutputLine (str, self.forceType, 2, true);
            
            str = self.addOutputLine (str, sprintf('%d', self.node.label), 2, true);
            
            addcomma = ~isempty (self.forceOrientation) ...
                        || ~isempty (self.momentOrientation) ...
                        || ~isempty (self.forceValue) ...
                        || ~isempty (self.moment);
            
            if ~isempty (self.position)
                str = self.addOutputLine ( str, ...
                                           self.commaSepList ( 'position', ...
                                                               'reference', ...
                                                               self.positionReference, ...
                                                               self.position ), ...
                                           2, ...
                                           addcomma );
            end
            
            addcomma = ~isempty (self.momentOrientation) ...
                        || ~isempty (self.forceValue) ...
                        || ~isempty (self.moment);
                    
            if ~isempty (self.forceOrientation)
                str = self.addOutputLine ( str, ...
                                           self.commaSepList ( 'force orientation', ...
                                                               'reference', ...
                                                               self.forceOrientationReference, ...
                                                               self.forceOrientation ), ...
                                           2, ...
                                           addcomma );
            end
            
            addcomma = ~isempty (self.forceValue) ...
                        || ~isempty (self.moment);
            
            if ~isempty (self.momentOrientation)
                str = self.addOutputLine ( str, ...
                                           self.commaSepList ( 'moment orientation', ...
                                                               'reference', ...
                                                               self.momentOrientationReference, ...
                                                               self.momentOrientation ), ...
                                           2, ...
                                           addcomma );
            end
            
            addcomma = ~isempty (self.moment);
                    
            if ~isempty (self.forceValue)
                str = self.addOutputLine (str, self.forceValue.generateMBDynInputString(), 2, addcomma);
            end
            
            if ~isempty (self.moment)
                str = self.addOutputLine (str, self.moment.generateMBDynInputString(), 2, false);
            end

            str = self.addOutputLine (str, ';', 1, false, 'end structural force');
            
        end
        
    end
    
    methods (Static)
        
        function [ options, nopass_list ] = defaultConstructorOptions ()
            
            options = mbdyn.pre.force.defaultConstructorOptions ();
            
            parentfnames = fieldnames (options);
            
            options.Position = 'null';
            options.PositionReference = 'node';
            options.ForceOrientation = [];
            options.ForceOrientationReference = 'node';
            options.MomentValue = [];
            options.MomentOrientation = [];
            options.MomentOrientationReference = 'node';
            
            allfnames = fieldnames (options);
            
            nopass_list = setdiff (allfnames, parentfnames);

        end
        
    end
    
end