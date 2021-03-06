classdef element < mbdyn.pre.base
% base class for all MBDyn elements
%
% Syntax
%
% el = mbdyn.pre.element ('Parameter', Value)
%
% Description
%
% mbdyn.pre.element is the base class for all other element types in the
% toolbox. It contains methods and properties common to all elements such
% as bodies, joints and forces etc. It is not intended to be used directly
% by ordinary users.
%
% mbdyn.pre.element Methods:
%
%   element - mbdyn.pre.element constructor
%   draw - plot the element in a figure
%   loadSTL - load an STL file which will be used when visualising the element
%   setColour - set the colour of the element in plots
%   setSize - set the size of the element in plots
%   
%
    
    properties (GetAccess = public, SetAccess = public)
       
        name; % name of the element
        defaultShape;
        defaultShapeOrientation;
        defaultShapeOffset;
        
    end
    
    properties (GetAccess = public, SetAccess = protected)
       
        stlLoaded;
        
    end
    
    properties (GetAccess = protected, SetAccess = protected)
       
        stlNormals;
        
    end
    
    methods
        
        function self = element (varargin)
            % mbdyn.pre.element constructor
            %
            % Syntax
            %
            % el = mbdyn.pre.element ('Parameter', Value)
            %
            % Description
            %
            % mbdyn.pre.element is the base class for all other element
            % types in the toolbox. It contains methods and properties
            % common to all elements such as bodies, joints and forces etc.
            % It is not intended to be used directly by ordinary users.
            %
            % Input
            %
            % Arguments may be supplied as parameter-value pairs. The
            % available options are:
            %
            %  'STLFile' - character vector containing the full path to an
            %    STL file which will be used when visualising/plotting the
            %    element.
            %
            %  'UseSTLName' - true/false flag indicating whether to use the
            %    name embedded in the STL file as the name for this
            %    element, in which case it will be used in the 'name'
            %    property of the element.
            %
            %  'DefaultShape' - optional string which chooses the shape to
            %    use to represent the element in a plot when an STL file is
            %    not available. Possible values are 'none', 'cuboid',
            %    'box', 'cylinder', 'tube', 'pipe', or 'annularcylinder'.
            %    Default is cuboid.
            % 
            %  'DefaultShapeOrientation' - optional mbdyn.pre.orientmat
            %    object which sets the orientation of the default shape (see
            %    above). 
            %
            %  'DefaultShapeOffset' - optional 3 element column vector
            %    which sets the offset of the default shape (see
            %    above) from the default initial position. 
            %
            % Output
            %
            %  el - mbdyn.pre.element
            %
            
            [options, ~] = mbdyn.pre.element.defaultConstructorOptions ();
            
            options = parse_pv_pairs (options, varargin);
            
            self = self@mbdyn.pre.base ();
            
            self.defaultShape = options.DefaultShape;
                                      
            assert (ischar (options.Name), 'Name must be a character vector');
            
            self.stlLoaded = false;
            self.drawColour = [0.8, 0.8, 1.0];
            self.shapeData = {}; %struct([]);
            self.shapeObjects = {};
            self.drawAxesH = [];
            self.defaultShapeOrientation = options.DefaultShapeOrientation;
            self.defaultShapeOffset = options.DefaultShapeOffset;
            self.name = options.Name;
            
            if ~isempty (options.STLFile)
                if exist (options.STLFile, 'file')
                    self.loadSTL (options.STLFile, options.UseSTLName);
                else
                    error ('Supplied STL file %s does not appear to exist', options.STLFile);
                end
            end
            
            if ~isempty (options.Size)
                self.setSize (options.Size{:})
            end
            
        end
        
        function set.defaultShapeOffset (self, new_offset)
            
            self.checkCartesianVector (new_offset, true, 'defaultShapeOffset');
            
            self.defaultShapeOffset = new_offset;
            
        end
        
        function set.defaultShapeOrientation (self, new_orientation)
            
            self.checkOrientationMatrix ( new_orientation, ...
                                          true, ...
                                          'DefaultShapeOrientation' );
            
            self.defaultShapeOrientation = new_orientation;
            
        end
        
        function set.defaultShape (self, newshape)
            
            self.checkAllowedStringInputs ( newshape, ...
                                            { 'none', 'cuboid', 'box', 'cylinder', 'sphere', 'ellipsoid', 'tube', 'pipe', 'annularcylinder' }, ...
                                            true, ...
                                            'DefaultShape' );
                                        
            self.defaultShape = newshape;
            
            switch self.defaultShape
                
                case 'none'
                    % do nothing
                    
                case {'cuboid', 'box'}
                    
                    % cuboid, 3 arguments expected, x, y and z dimensions
                    self.setSize (1, 1, 1);

                case 'cylinder'
                    
                    % cylinder, two arguments expected, radius and axial
                    % length
                    self.setSize (1, 2);

                case {'tube', 'pipe', 'annularcylinder'}

                    % tube, 3 arguments expected, router, rinner and
                    % axiallength dimensions
                    self.setSize (1, 0.5, 2);

                case 'sphere'
                    
%                     self.setSize (1);

                case 'ellipsoid'


                otherwise
                    error ('Bad defaultShape string');
                        
            end
            
            self.needsRedraw = true;
            
        end
        
        function loadSTL (self, filename, usename)
            % load an STL file which will be used when visualising the element
            %
            % Syntax
            %
            % mbdyn.pre.element (self, filename, usename)
            %
            % Description
            %
            % load an STL file which will be used when visualising the
            % element instead of the default shapes.
            %
            % Input
            %
            %  el - mbdyn.pre.element object
            %
            %  filename - full path to the STL file to be loaded
            %
            %  usename - true/false 
            %
            %
            % See Also: mbdyn.pre.element.node
            %

            self.checkLogicalScalar (usename, true, 'usename');
            
            self.shapeData{1} = struct ();
            
            [self.shapeData{1}.Vertices, self.shapeData{1}.Faces, self.stlNormals, stlname] = stl.read(filename);
            
            if usename
                self.name = stlname;
            end
            
            self.stlLoaded = true;
            self.needsRedraw = true;
            
            setSize (self, ...
                max(self.shapeData{1}.Vertices(:,1)) - min(self.shapeData{1}.Vertices(:,1)), ...
                max(self.shapeData{1}.Vertices(:,2)) - min(self.shapeData{1}.Vertices(:,2)), ...
                max(self.shapeData{1}.Vertices(:,3)) - min(self.shapeData{1}.Vertices(:,3)) )
            
        end
        
        function setSize (self, varargin)
            % set the size of the element in plots
            %
            % Syntax
            %
            % setSize (el, sx, sy, sz)
            % setSize (el, radius, axiallength)
            % setSize (el, router, rinner, axiallength)
            % setSize (el, R)
            %
            % Description
            %
            % setSize is used to set the size of the default element shape
            % for plotting the element in a figure. This is used when no
            % STL file is avaialable, of the subclassed elemnt does not
            % provide it's own drawing of the element. The inputs to
            % setSize depend on what the element's chosen shape is.
            %
            % Input
            %
            %  el - mbdyn.pre.element object
            %
            %  sx - used when the shape is a box/cuboid, this is the
            %   length along the x axis
            %
            %  sy - used when the shape is a box/cuboid, this is the
            %   length along the y axis
            %
            %  sz - used when the shape is a box/cuboid, this is the
            %   length along the z axis
            %
            %  radius - used when the shape is a cylinder, this is the
            %   radius of the cylinder
            %
            %  axiallength - used when the shape is a cylinder, this is the
            %   axial length of the cylinder
            %
            %  router - used when the shape is a tube/pipe/annularcylinder,
            %   this is the outer radius of the tube.
            %
            %  rinner - used when the shape is a tube/pipe/annularcylinder,
            %   this is the inner radius of the tube.
            %
            %  axiallength - used when the shape is a tube/pipe/annularcylinder,
            %   this is the axial length of the tube.
            %
            %  R - used when the shape is a sphere, this is the radius of
            %   the sphere
            %
            %
            % Output
            %
            %
            %
            % See Also: 
            %

            if self.stlLoaded
                
                % shape bounding box, 3 arguments expected, x, y and z
                % dimensions
                assert (numel (varargin) == 3, ...
                        'setSize requires 3 size input arguments when the shape is from an STL file, sx, sy and sz, which represent the bounding box of the shape');

                self.checkNumericScalar (varargin{1}, true, 'sx');
                self.checkNumericScalar (varargin{2}, true, 'sy');
                self.checkNumericScalar (varargin{3}, true, 'sz');

                assert (varargin{1} > 0, 'sx must be greater than zero');
                assert (varargin{2} > 0, 'sy must be greater than zero');
                assert (varargin{3} > 0, 'sz must be greater than zero');

                self.shapeParameters(1) = varargin{1};
                self.shapeParameters(2) = varargin{2};
                self.shapeParameters(3) = varargin{3};
                        
            else
                
                switch self.defaultShape

                    case 'none'

                        warning ('Default shape is set to ''none'', setting the size has no effect');

                    case {'cuboid', 'box'}

                        % cuboid, 3 arguments expected, x, y and z dimensions
                        assert (numel (varargin) == 3, ...
                                'setSize requires 3 size input arguments when the shape is a box/cuboid, sx, sy and sz');

                        self.checkNumericScalar (varargin{1}, true, 'sx');
                        self.checkNumericScalar (varargin{2}, true, 'sy');
                        self.checkNumericScalar (varargin{3}, true, 'sz');

                        assert (varargin{1} > 0, 'sx must be greater than zero');
                        assert (varargin{2} > 0, 'sy must be greater than zero');
                        assert (varargin{3} > 0, 'sz must be greater than zero');

                        self.shapeParameters(1) = varargin{1};
                        self.shapeParameters(2) = varargin{2};
                        self.shapeParameters(3) = varargin{3};

                    case 'cylinder'

                        % cylinder, two arguments expected, radius and axial
                        % length
                        assert (numel (varargin) == 2, ...
                                'setSize requires 2 size input arguments when the shape is a cylinder, radius, axiallength');

                        self.checkNumericScalar (varargin{1}, true, 'radius');
                        self.checkNumericScalar (varargin{2}, true, 'axiallength');

                        assert (varargin{1} > 0, 'radius must be greater than zero');
                        assert (varargin{2} > 0, 'axiallength must be greater than zero');

                        self.shapeParameters(1) = varargin{1};
                        self.shapeParameters(2) = varargin{2};


                    case {'tube', 'pipe', 'annularcylinder'}

                        % tube, 3 arguments expected, router, rinner and
                        % axiallength dimensions
                        assert (numel (varargin) == 3, ...
                                'setSize requires 3 size input arguments when the shape is a tube/pipe/annularcylinder, router, rinner and axiallength');

                        self.checkNumericScalar (varargin{1}, true, 'router');
                        self.checkNumericScalar (varargin{2}, true, 'rinner');
                        self.checkNumericScalar (varargin{3}, true, 'axiallength');

                        assert (varargin{1} > 0, 'router must be greater than zero');
                        assert (varargin{2} > 0, 'rinner must be greater than zero');
                        assert (varargin{1} > varargin{2}, 'router must be greater than rinner');
                        assert (varargin{3} > 0, 'axiallength must be greater than zero');

                        self.shapeParameters(1) = varargin{1};
                        self.shapeParameters(2) = varargin{2};
                        self.shapeParameters(3) = varargin{3};

                    case 'sphere'

%                         % sphere, 1 argument expected, radius
%                         assert (numel (varargin) == 1, ...
%                                 'setSize requires 1 size input arguments when the shape is a sphere, R, the radius');
% 
%                         self.checkNumericScalar (varargin{1}, true, 'R');
% 
%                         assert (varargin{1} > 0, 'sx must be greater than zero');
% 
%                         self.shapeParameters(1) = varargin{1};

                    case 'ellipsoid'


                    otherwise
                        error ('Bad defaultShape string');

                end

                % set the shapedata to empty so it is recreated with the new
                % sizes when draw is next called
                self.shapeData = [];
            
            end
            
        end
        
        function setColour (self, newcolour)
            % set the colour of the element in plots
            
            self.drawColour = newcolour;
        end
        
        function hax = draw (self, varargin)
            % plot the element in a figure
            %
            % Syntax
            %
            % hax = draw (el)
            % hax = draw (..., 'Parameter', Value)
            %
            % Description
            %
            % The draw method creates a visualisation of the element in a
            % figure. If an STL file has previously be added to the
            % element, this will be plotted. Otherwise a standard shape
            % will be used.
            %
            % The draw method tries to be efficient. Each element is
            % associated with a hgtransform object. If the shape of the
            % object has not changed, the transform matrix is simply
            % updated to adjust the location and orientation on the plot. 
            %
            % Input
            %
            %  el - mbdyn.pre.element object
            %
            % Addtional arguments may be supplied as parameter-value pairs.
            % The available options are:
            %
            %  'AxesHandle' - optional handle to axes in which to plot the
            %    element. If not supplied, a new figure and axes will be
            %    created. The first time the element is drawn the handle to
            %    the axes will be stored internally and future calls to
            %    draw will plot to the same axes, unless the axes are
            %    destroyed, or this option is used to override it.
            %
            %  'ForceRedraw' - true/false flag indicating whether to force
            %    a full redraw of the object (rather than just update the
            %    transform matrix), even if the element does not think it
            %    needs it.
            %
            %  'Mode' - character vector determining the style in which the
            %    element will be plotted. Can be one of 'solid',
            %    'wiresolid', 'ghost', 'wireframe', 'wireghost'. Default is
            %    'solid'.
            %
            %  'Light' - deterined whether the scene should have light
            %    source
            %
            % Output
            %
            %
            %
            % See Also: 
            %

            options.AxesHandle = [];
            options.ForceRedraw = false;
            options.Mode = 'solid';
            options.Light = false;
            options.SaveShapeData = '';
            
            options = parse_pv_pairs (options, varargin);
            
            self.checkLogicalScalar ( options.ForceRedraw, true, 'ForceRedraw' );
            self.checkAllowedStringInputs ( options.Mode, ...
                                            { 'solid', ...
                                              'wiresolid', ...
                                              'ghost', ...
                                              'wireframe', ...
                                              'wireghost' }, ...
                                            true, ...
                                            'Mode' );
            self.checkLogicalScalar ( options.Light, true, 'Light' );
            
            if options.ForceRedraw
                self.needsRedraw = true;
            end
            
            self.checkAxes (options.AxesHandle);
            
            if isempty (self.shapeData)
                
                switch self.defaultShape
                    
                    case 'none'
                        
                        self.shapeData = {};
                    
                    case {'cuboid', 'box'}
                        
                        lx = self.shapeParameters(1);
                        ly = self.shapeParameters(2);
                        lz = self.shapeParameters(3);
                        
                        orientation = self.defaultShapeOrientation.orientationMatrix;
                        
                        offset = self.defaultShapeOffset;
                        
                        self.shapeData = self.makeCuboidShape (lx, ly, lz, orientation, offset);
                        
                                     
                    case 'cylinder'
                        
                        radius = self.shapeParameters(1);
                        axiallength = self.shapeParameters(2);
                        orientation = self.defaultShapeOrientation.orientationMatrix;
                        offset = self.defaultShapeOffset;
                        npnts = 30;
                        
                        self.shapeData = self.makeCylinderShape (radius, axiallength, orientation, offset, npnts);
                        
                        
                    case {'tube', 'pipe', 'annularcylinder'}
                        
                        router = self.shapeParameters(1);
                        rinner = self.shapeParameters(2);
                        axiallength = self.shapeParameters(3);
                        orientation = self.defaultShapeOrientation.orientationMatrix;
                        offset = self.defaultShapeOffset;
                        npnts = 20;
                        
                        self.shapeData = self.makeAnnularCylinderShape (router, rinner, axiallength, orientation, offset, npnts);
                        
                        
                    case 'sphere'
                        
                        
                    case 'ellipsoid'
                        
                        
                    otherwise
                        error ('Bad defaultShape string');
                        
                end
                                     
                self.needsRedraw = true;
                
            end
            
            if isempty (self.shapeObjects) ...
                    || self.needsRedraw
                % a full redraw is needed (and not just a modification of
                % transform matrices for the objects).
                
                % delete the current patch object
                self.deleteAllDrawnObjects ();
                self.shapeObjects = {};
                
                for ind = 1:numel (self.shapeData)
                    if all ( isfield (self.shapeData{ind}, {'Faces', 'Vertices'})) ...
                        || all (isfield (self.shapeData{ind}, {'XData', 'YData', 'ZData'}))

                        self.shapeData{ind}.FaceLighting = 'Gouraud';
                        self.shapeData{ind}.AmbientStrength = 0.15;
                        self.shapeData{ind}.Parent = self.transformObject;
                        
                        if isoctave () && self.stlLoaded
                            self.shapeData{ind}.FaceNormals = self.stlNormals;
                        end
                        
                        self.shapeObjects = [ self.shapeObjects, ...
                                              { patch( self.drawAxesH, ...
                                                       self.shapeData{ind} ) } ...
                                             ];

                    else
                        error ('Invalid shape data');
                    end
                end
                
                self.needsRedraw = false;
                
                if options.Light
                    light (self.drawAxesH);
                end
               
            end
            
            for ind = 1:numel (self.shapeObjects)
                
                switch options.Mode

                    case 'solid'
                        set (self.shapeObjects{ind}, 'FaceAlpha', 1.0);
                        set (self.shapeObjects{ind}, 'FaceColor', self.drawColour);
                        set (self.shapeObjects{ind}, 'EdgeColor', 'none');
                    case 'wiresolid'
                        set (self.shapeObjects{ind}, 'FaceAlpha', 1.0);
                        set (self.shapeObjects{ind}, 'FaceColor', self.drawColour);
                        set (self.shapeObjects{ind}, 'EdgeColor', self.drawColour);
                    case 'ghost'
                        set (self.shapeObjects{ind}, 'FaceAlpha', 0.25);
                        set (self.shapeObjects{ind}, 'FaceColor', self.drawColour);
                        set (self.shapeObjects{ind}, 'EdgeColor', 'none');
                    case 'wireframe'
                        set (self.shapeObjects{ind}, 'EdgeColor', self.drawColour);
                        set (self.shapeObjects{ind}, 'FaceColor', 'none');
                    case 'wireghost'
                        set (self.shapeObjects{ind}, 'EdgeColor', self.drawColour);
                        set (self.shapeObjects{ind}, 'FaceColor', self.drawColour);
                        set (self.shapeObjects{ind}, 'FaceAlpha', 0.25);

                    otherwise
                        set (self.shapeObjects{ind}, 'FaceAlpha', 1.0);
                        set (self.shapeObjects{ind}, 'FaceColor', self.drawColour);
                        set (self.shapeObjects{ind}, 'EdgeColor', 'none');

                end
            
            end
            
            if ~isempty (options.SaveShapeData)
                
                % mostly for debugging plotting in octave
                s = self.shapeData;
                
                save (options.SaveShapeData, 's');
                
            end
            
            if nargout > 0
                hax = self.drawAxesH;
            end
        end
        
        function str = generateMBDynInputString (self)
            % generates MBDyn input string for common element
            % 
            % Syntax
            %  
            % str = generateMBDynInputString (jnt)
            %  
            % Description
            %  
            % generateMBDynInputString is a method shared by all MBDyn
            % components and is called to generate a character vector used
            % to construct an MBDyn input file.
            %  
            % Input
            %  
            %  jnt - mbdyn.pre.joint object
            %  
            % Output
            %  
            %  str - character vector for insertion into an MBDyn input
            %   file.
            %
            
            str = sprintf ('    %s', self.elementNameComment ());
            
        end
        
    end
    
    methods (Access = protected)
        
        function ok = checkInertiaMatrix (self, mat, throw)
            
            ok = self.check3X3Matrix (mat, false);
            
            if ~ok && throw
                error ('Inertia matrix must be a 3 x 3 numeric matrix');
            end
            
        end
        
        function ok = checkCOGVector (self, cog, throw)
            
            if isempty (cog) || (ischar (cog) && strcmp (cog, 'null'))
                ok = true;
            else
                ok = self.checkCartesianVector (cog, false);
            end
            
            if ~ok && throw
                error ('Centre of gravity offset must 3 element numeric column vector, or keyword ''null'' or empty');
            end
            
            
        end
        
        
        function comment = elementNameComment (self)
            % generate a comment describing an element (uses name if present)
            % 
            % Syntax
            %
            % comment = nodeLabelComment (el)
            %
            % Input
            %
            %  el - mbdyn.pre.element (or derived) object
            %
            % Output
            %
            %  comment - string containing a comment including the 
            %   element's name if not empty
            %
            
            
            if isempty (self.name)
                comment = sprintf ('# %s', self.type);
            else 
                comment = sprintf ('# %s with name %s ', self.type, self.name);
            end
            
        end
        
    end
    
    methods
        
        function set.name (self, newname)
            
            assert (ischar (newname), 'name must be a character vector');
            
            self.name = newname;
            
        end
        
    end
    
    methods (Static)
                
        function comment = nodeLabelComment (node)
            % generate a comment describing a node (uses label or name if present)
            % 
            % Syntax
            %
            % comment = mbdyn.pre.base.nodeLabelComment (node)
            %
            % Input
            %
            %  node - mbdyn.pre.node object
            %
            % Output
            %
            %  comment - string containing a coomen including the node's
            %   name if not empty
            %
            
            
            if isempty (node.name)
                comment = sprintf ('node label');
            else 
                comment = sprintf ('node label %s', node.name);
            end
            
        end
        
        function [options, nopass_list] = defaultConstructorOptions ()
            
            options.STLFile = '';
            options.UseSTLName = false;
            options.Name = '';
            options.DefaultShape = 'cuboid';
            options.DefaultShapeOrientation = mbdyn.pre.orientmat ('eye');
            options.DefaultShapeOffset = [0;0;0];
            options.Size = [];
            
            nopass_list = {};
            
        end
        
        function shapedata = makeCylinderShape (radius, axiallength, orientation, offset, npnts)
            % generate shape data for a closed cylinder
            
            if nargin < 5
                npnts = 30;
            end
            
            if nargin < 4
                offset = [0;0;0];
            end
            
            if nargin < 3
                orientation = eye (3);
            end
            
            % make a unit length cylinder
            [X,Y,Z] = cylinder (radius, npnts-1);
            % scale the Z coordinates to give the desired axial length
            Z = Z .* axiallength;
            % shift it down so centre is at origin
            Z = Z - axiallength/2;

            % rotate
            XYZtemp = [ X(1,:);
                        Y(1,:)
                        Z(1,:) ];

            XYZtemp = orientation * XYZtemp;

            X(1,:) = XYZtemp(1,:);
            Y(1,:) = XYZtemp(2,:);
            Z(1,:) = XYZtemp(3,:);

            XYZtemp = [ X(2,:);
                        Y(2,:)
                        Z(2,:) ];

            XYZtemp = orientation * XYZtemp;

            X(2,:) = XYZtemp(1,:);
            Y(2,:) = XYZtemp(2,:);
            Z(2,:) = XYZtemp(3,:);

            shapedata{1} = struct ();
            shapedata{1}.Vertices = [];
            shapedata{1}.Faces = [];

            shapedata{1}.Vertices = [ X(1,:)', Y(1,:)', Z(1,:)';
                                      X(2,:)', Y(2,:)', Z(2,:)'; ] + offset.';

            shapedata{1}.Faces = [ (1:npnts)', (1:npnts)' + 1, (1:npnts)' + 1 + npnts, (1:npnts)' + npnts ];
            shapedata{1}.Faces (end, 2) = 1;
            shapedata{1}.Faces (end, 3) = 1 + npnts;

            shapedata{2} = struct ();
            shapedata{2}.Vertices = [ X(1,:)', Y(1,:)', Z(1,:)' ] + offset.';
            shapedata{2}.Faces = 1:npnts;

            shapedata{3} = struct ();
            shapedata{3}.Vertices = [ X(2,:)', Y(2,:)', Z(2,:)' ] + offset.';
            shapedata{3}.Faces = 1:npnts;     
            
        end
        
        
        function shapedata = makeAnnularCylinderShape (router, rinner, axiallength, orientation, offset, npnts)
            
            if nargin < 6
                npnts = 20;
            end
            
            if nargin < 5
                offset = [0;0;0];
            end
            
            if nargin < 4
                orientation = eye (3);
            end
            
            [Xo,Yo,Zo] = cylinder (router, npnts-1);
            Zo = Zo .* axiallength;

            [Xi,Yi,Zi] = cylinder (rinner, npnts-1);
            Zi = Zi .* axiallength;

            Zo = Zo - axiallength/2;
            Zi = Zi - axiallength/2;

            % rotate
            XYZtemp = [ Xo(1,:);
                        Yo(1,:)
                        Zo(1,:) ];

            XYZtemp = orientation * XYZtemp;

            Xo(1,:) = XYZtemp(1,:);
            Yo(1,:) = XYZtemp(2,:);
            Zo(1,:) = XYZtemp(3,:);

            XYZtemp = [ Xo(2,:);
                        Yo(2,:)
                        Zo(2,:) ];

            XYZtemp = orientation * XYZtemp;

            Xo(2,:) = XYZtemp(1,:);
            Yo(2,:) = XYZtemp(2,:);
            Zo(2,:) = XYZtemp(3,:);

            XYZtemp = [ Xi(1,:);
                        Yi(1,:)
                        Zi(1,:) ];

            XYZtemp = orientation * XYZtemp;

            Xi(1,:) = XYZtemp(1,:);
            Yi(1,:) = XYZtemp(2,:);
            Zi(1,:) = XYZtemp(3,:);

            XYZtemp = [ Xi(2,:);
                        Yi(2,:)
                        Zi(2,:) ];

            XYZtemp = orientation * XYZtemp;

            Xi(2,:) = XYZtemp(1,:);
            Yi(2,:) = XYZtemp(2,:);
            Zi(2,:) = XYZtemp(3,:);


            shapedata{1} = struct ();
            shapedata{1}.Vertices = [];
            shapedata{1}.Faces = [];

            shapedata{1}.Vertices = [ Xo(1,:)', Yo(1,:)', Zo(1,:)';
                                      Xo(2,:)', Yo(2,:)', Zo(2,:)'; ] + offset.';

            shapedata{1}.Faces = [ (1:npnts)', (1:npnts)' + 1, (1:npnts)' + 1 + npnts, (1:npnts)' + npnts ];
            shapedata{1}.Faces (end, 2) = 1;
            shapedata{1}.Faces (end, 3) = 1 + npnts;

            shapedata{2}.Vertices = [ Xi(1,:)', Yi(1,:)', Zi(1,:)';
                                      Xi(2,:)', Yi(2,:)', Zi(2,:)'; ] + offset.';

            shapedata{2}.Faces = [ (1:npnts)', (1:npnts)' + 1, (1:npnts)' + 1 + npnts, (1:npnts)' + npnts ];
            shapedata{2}.Faces (end, 2) = 1;
            shapedata{2}.Faces (end, 3) = 1 + npnts;

            shapedata{3} = struct ();
            shapedata{3}.Vertices = [ Xo(1,:)', Yo(1,:)', Zo(1,:)';
                                      Xi(1,:)', Yi(1,:)', Zi(1,:)'; ] + offset.';
            shapedata{3}.Faces = [ 1:npnts, 1, (1:npnts) + npnts, 1 + npnts ];

            shapedata{4} = struct ();
            shapedata{4}.Vertices = [ Xo(2,:)', Yo(2,:)', Zo(2,:)';
                                      Xi(2,:)', Yi(2,:)', Zi(2,:)'; ] + offset.';
            shapedata{4}.Faces = [ 1:npnts, 1, (1:npnts) + npnts, 1 + npnts ];
                        
        end
        
        function shapedata = makeCuboidShape (lx, ly, lz, orientation, offset)
            
            if nargin < 5
                offset = [0;0;0];
            end
            
            if nargin < 4
                orientation = eye (3);
            end
            
            shapedata{1} = struct ();
            
            % make a unit box by default for drawing
            shapedata{1}.Vertices = [ -lx/2, -ly/2, -lz/2;
                                       lx/2, -ly/2, -lz/2;
                                       lx/2,  ly/2, -lz/2;
                                      -lx/2,  ly/2, -lz/2;
                                      -lx/2, -ly/2,  lz/2;
                                       lx/2, -ly/2,  lz/2;
                                       lx/2,  ly/2,  lz/2;
                                      -lx/2,  ly/2,  lz/2; ];
                                  
            shapedata{1}.Vertices = (orientation * shapedata{1}.Vertices.').'  + offset.';

            shapedata{1}.Faces = [ 1, 4, 3, 2;
                                   1, 5, 6, 2;
                                   2, 6, 7, 3;
                                   7, 8, 4, 3;
                                   8, 5, 1, 4;
                                   8, 7, 6, 5 ];
                               
        end
        
%         function shapedata = makeSphereShape (R, orientation)
%             
%             if nargin < 2
%                 orientation = eye (3);
%             end
%             
%             angle = 0;
%             
%             [x, y, z] = sph2cart ( linspace (0, pi, nsides), ...
%                                    repmat (angle, 1, nsides), ...
%                                    repmat (R, 1, nsides) );
%                                    
%             shapedata{1} = struct ();
%             shapedata{1}.Vertices = [];
%             shapedata{1}.Faces = [];
%             
%             nsides = 20;
%             
%             
%             for ind = 1:nsides
%                
%                 [x, y, z] = sph2cart ( linspace (0, pi, nsides), ...
%                                        repmat (angle, 1, nsides), ...
%                                        repmat (R, 1, nsides) );
%                 
%                 angle = angle + (2*pi)/nsides;
%                 
%                 shapedata{1}.Vertices = [ shapedata{1}.Vertices;
%                                           x(:), y(:), z(:); ];
%                                       
%                 shapedata{1}.Faces = [ shapedata{1}.Faces; 
%             end
%             
%                                
%         end

    end
    
end