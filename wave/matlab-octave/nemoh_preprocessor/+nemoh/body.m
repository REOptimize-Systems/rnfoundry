classdef body < nemoh.base
    % class representing a body in a NEMOH hydrodynamic calculation
    %
    % Syntax
    %
    % nb = nemoh.body (inputdir)
    % nb = nemoh.body (inputdir, 'Parameter', value)
    %
    % Description
    %
    % the nemoh.body class represents a hydrodynamic body for input to a
    % NEMOH calculation. One or more body classes are used together with
    % the nemoh.simulation object to generate NEMOH input files and
    % compatible meshes to perform hydrodynamic BEM calculations. For the
    % general workflow of running a calculation see the help for the
    % nemoh.simulation class.
    %
    % body Methods:
    % 
    %  body - constructor for the body object
    %  makeAxiSymmetricMesh - initialises a mesh of an axisymmetric body
    %    defined by a 2D profile rotated around z axis.
    %  makeCylinderMesh - create axisymmetric cylinder mesh
    %  makeSphereMesh - create axisymmetric sphere mesh
    %  loadNemohMesherInputFile - load mesh from an input file for the
    %    Nemoh meshing program 
    %  loadNemohMeshFile - load mesh from an mesh file for the
    %    Nemoh preprocesor and solver
    %  drawMesh - plots the body mesh in a figure
    %  meshInfo - prints some information about the body mesh to the
    %    command line
    %  setTargetPanels - sets the target number of panels in refined
    %    mesh
    %  scaleMesh - scale the mesh vertex location data by a factor
    %  writeSTL - writes a triangle mesh of the body to an STL file
    %
    % The folowing methods are mainly for use by a nemoh.simulation object
    % to which the body has been added:
    %
    %  writeMesh - writes mesh input files, these usually require procesing
    %    by calling processMesh after writing the files. 
    %  processMesh - process the mesh files written by writeMesh, e.g. by
    %    running the NEMOH meshing program. 
    %  setMeshProgPath - sets the path to the NEMOH meshing program
    %  setRho - sets the water density for the problem
    %  setg - sets the gravitational acceleration for the problem
    %  setID - sets the integer ID of the body
    %  generateBodyStr - create a string for the body representing the body
    %    section of a NEMOH.cal file
    %
    % See also: nemoh.simulation, example_nemoh_cylinder.m
    %
    
    properties (GetAccess = public, SetAccess = private)
        
        meshProgPath; % nemoh mesh program file path
        
        inputDataDirectory; % directory where NEMOH mesh files will be created
        
        axiMeshR; % radial coordinates of axisymmetric body profile data
        axiMeshZ; % axial coordinates of axisymmetric body profile data
        
        meshVertices; % X,Y,Z coordinates of mesh
        
        nQuads;
        quadMesh;
        triMesh;
        triMeshVertices;
        nMeshNodes;
        nPanelsTarget; % Target for number of panels in mesh refinement
        centreOfGravity;
        meshBoundBox;
        meshSize;
        meshTranslation;
        
        hydrostaticForces; % hydrostatic forces
        hydrostaticForcePoints; % X,Y,Z coordinates where hydrostatic forces were calculated
        
        rho; % fluid density for problem
        g; % acceleration due to gravity for problem
        
        centreOfBuoyancy; % X,Y,Z cordinates of centre of buoyancy
        kH  % hydrostatic stiffness matrix
        volume; % volume of mesh
        mass; % mass of buoy
        WPA;
        inertia; % inertia matrix (estimated assuming mass is distributed on wetted surface)
        
        meshProcessed; % flag showing whether the current body mesh is ready for writing or needs processing
        
        meshFileName; % mesh filename (without full path)
        meshInputDirectory % directory mesh input files will be written to
        meshDirectory; % directory mesh will be written to 
        meshFilePath; % full path to mesh ('.dat') file
        
        id; % integer body id 
        name; % string body name, usually generated from id
        uniqueName; % unique name derived from name and id
        meshType; % string indicating the type of mesh specification used for the body (e.g. 'axi')
        
        haveGIBBON;
        
        % degreesOfFreedom - degrees of freedom to be solved for the body
        %  This will be a cell array of objects derived from the
        %  nemoh.degreeOfFreedom class, e.g. nemoh.translationalDoF and
        %  nemoh.rotationalDoF
        degreesOfFreedom; 
        
    end
    
    properties (GetAccess = private, SetAccess = private)
       meshPlottable; 
       sanitizedName; % name, but altered if necessary to be valid file name
       stlLoaded;
       defaultTargetPanels;
    end
    
    methods
        
        function self = body (inputdir, varargin)
            % constructor for the nemoh.body object
            %
            % Syntax
            %
            % nb = nemoh.body (inputdir)
            % nb = nemoh.body (inputdir, 'Parameter', value)
            %
            % Input
            %
            %  inputdir - string containing the directory where the NEMOH
            %    input files are to be generated and evaluated
            %
            % Additional optional arguments can be supplied using
            % parameter-value pairs. The available options are:
            %
            % 'MeshProgPath' - string containng the path of the NEMOH 
            %   meshing program executeable. If not supplied, the default
            %   is an empty string, which means the meshing program must be
            %   on your computer's program path (it will be invoked by just
            %   calling the mesh program's name). MeshProgPath can be set
            %   later using the setMeshProgPath method. When the body is
            %   added to a nemoh.simulation object, the system object calls
            %   setMeshProgPath to match the path set in the system object.
            %
            % 'Name' - string containing a user-defined name for the body.
            %   Mesh files etc. will be given names generated from this
            %   string. The name is stored in the "name" property, and the
            %   name generated from this is stored in the "uniqueName"
            %   property. The unique name is generated using the id for the
            %   body, and is changed when the id is changed.
            %
            % 'DegreesOfFreedom' - can be a character vector, contating a
            %   keyword indicating a special setting for the degrees of
            %   freedom for which motion is to be considered, or a cell
            %   array containing one or more nemoh.translationalDoF objects
            %   and/or nemoh.rotationalDoF objects. The following
            %   keywords are available:
            % 
            %     'default' : The use of this keyword indicates that the 
            %       translational degrees of freedom parallel to the x, y,
            %       and z axes will be considered, and the rotational
            %       degrees of freedom about the x, y and z axes with a
            %       rotation point at the body centre of gravity will also
            %       be considered. 
            %
            %     'none' : equivalent to an empty cell array, no degrees of
            %       freedom will be considered.
            %
            %   Default is: 'default' if not supplied.
            %
            %
            
            options.MeshProgPath = '';
            options.Name = 'body';
            options.DegreesOfFreedom = 'default';
            
            options = parse_pv_pairs (options, varargin);
            
            if isempty (options.MeshProgPath)
                if ispc
                    options.MeshProgPath = 'Mesh';
                else
                    options.MeshProgPath = 'mesh';
                end
            end
            
            if isempty (options.Name) || ~ischar (options.Name)
                error ('Name must be a string of length greater than 1')
            end

            if ~exist (inputdir, 'dir')
                [status, msg] = mkdir (inputdir);
                if status == false
                    error ('inputdir does not exist and creation failed with the following message:\n%s', ...
                        msg);
                end
            end
            
            self.setMeshProgPath (options.MeshProgPath)
            
            self.inputDataDirectory = inputdir;
            
            self.clearMeshAndForceData ();

            self.id = 0;
            self.setName (options.Name);
            
            self.degreesOfFreedom = options.DegreesOfFreedom;
            
            % internal flags
            self.stlLoaded = false;
            self.meshPlottable = false;
            self.haveGIBBON = exist ('discQuadMesh', 'file') == 2;
            self.meshTranslation = [0;0;0];
            
        end
        
        function setName (self, newname)
            % sets the body name
            
            
            self.name = newname;
            
            % sanitize the name
            
            % replace any whitespace with _
            self.sanitizedName = regexprep (self.name, '\s+', '_');
            
            % replace filesep char with _
            self.sanitizedName = strrep (self.sanitizedName, filesep (), '_');
            
            % Replace non-word character with its HEXADECIMAL equivalent
            if ~isoctave ()
                % for some reason the following call to unique fails in Octave 
                % (as of Octave 5.1.0).
                badchars = unique ( self.sanitizedName( regexp (self.sanitizedName,'[^A-Za-z_0-9]') ) );
                for ind = 1:numel (badchars)
                    if badchars(ind) <= intmax('uint8')
                        width = 2;
                    else
                        width = 4;
                    end
                    replace = ['0x', dec2hex(badchars(ind), width)];
                    self.sanitizedName = strrep (self.sanitizedName, badchars(ind), replace);
                end
            end
            
            self.uniqueName = sprintf('%s_id_%d', self.sanitizedName, self.id);
            
        end
        
        function setCentreOfBuoyancy (self, CoB)

            assert ( isnumeric (CoB) && size(CoB,1) == 3 && size(CoB,2) == 1, ...
                     'CoB must be a (3 x 1) numeric column vector' );

            self.centreOfBuoyancy = CoB;

        end
        
        function setCentreOfGravity (self, CoG)

            assert ( isnumeric (CoG) && size(CoG,1) == 3 && size(CoG,2) == 1, ...
                     'CoB must be a (3 x 1) numeric column vector' );

            self.centreOfGravity = CoG;

        end
        
        function setVolume (self, vol)

            assert ( isnumeric (vol) && isscalar (vol) && vol >= 0, ...
                     'CoB must be a numeric scalar >= 0' );

            self.volume = vol;

        end
        
        function setMeshProgPath (self, meshprogpath)
            % set the path on which to call the NEMOH meshing program
            %
            % Syntax
            %
            % setMeshProgPath (n, meshprogpath)
            %
            % Description
            %
            % sets the path on which to call the NEMOH meshing program. If
            % the meshing program is on your program path, this can just be
            % the program name (e.g. 'Mesh.exe' on windows and 'mesh' on
            % other platforms. This is the default if you do not set this
            % value by calling setMeshProgPath of using the optional
            % 'MeshProgPath' option when constructing the body.
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            %  meshprogpath - string containing the full path to the NEMOH
            %    meshing program executeable. 
            %
            %
            
            if ~isempty (meshprogpath)
                
                if ~strcmp (meshprogpath, 'Mesh')
                    
                    if ~exist (meshprogpath, 'file')
                        
                        error ('MeshProgPath does not exist');
                        
                    end
                    
                end
                
            end
            
            self.meshProgPath = meshprogpath;
            
        end
        
        function setRho (self, rho)
            % sets rho, the water density for the problem
            
            self.checkNumericScalar (rho, true, 'rho');
            
            self.rho = rho;
            
        end
        
        function setg (self, g)
            % sets g, the gravitational acceleration for the problem
            
            self.checkNumericScalar (g, true, 'g');
            
            self.g = g;
            
        end
        
        function setID (self, id)
            % set the id of the body
            %
            % Syntax
            %
            % setID (nb, id)
            %
            % Description
            %
            % setID sets the integer value identifying the body. This id is
            % used to generate the body's name, which is also used by
            % default in the mesh file name. When the body is put into a
            % nemoh.simulation object the system sets all body ids in the
            % system automatically (by callng this method).
            % 
            % Input
            %
            %  nb - nemoh.body object
            %
            %  id - new id, should be a sclar integer value
            %
            %
            
            self.checkScalarInteger (id, true, 'id');
            
            if id < 0
                error ('id must be zero, or a positive integer, not negative');
            end
            
            self.id = id;
            
            self.uniqueName = sprintf('%s_id_%d', self.sanitizedName, self.id);
            
        end
        
        function setTargetPanels (self, newtargetpanels)
            % set the defaultTargetPanels property
            %
            % Syntax
            %
            % setTargetPanels (nb, newtargetpanels)
            %
            % Description
            %
            % setTargetPanels sets the value of the defaultTargetPanels
            % property. This property is used when generating mesh input
            % files for the NEMOH meshing program to set the taget number
            % of panels in the refined mesh. It can be overriden by an
            % optional argument to the processMesh method. The initial
            % value is 250.
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            %  newtargetpanels - new value for the defaultTargetPanels
            %    property
            %
            
            self.checkScalarInteger (newtargetpanels, true, 'newtargetpanels');
            
            self.defaultTargetPanels = newtargetpanels;
            self.nPanelsTarget = self.defaultTargetPanels;
            
        end
        
        function loadSTLMesh (self, filename, varargin)
            % load mesh from STL file
            %
            % Syntax
            %
            % loadSTLMesh (nb, filename)
            % loadSTLMesh (nb, filename, 'Parameter', value)
            %
            % Description
            %
            % loadSTLMesh imports a mesh from an STL file.
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            %  filename - stl file name
            %
            % Additional optional arguments may be supplied using
            % parameter-value pairs. The available options are:
            %
            % 'Draft' - distance from the lowest point on the mesh to the
            %   water free surface. The mesh will be translated such that
            %   the specified draft is achieved. If Draft is empty the
            %   displacement is kept as it is in the STL file. This is
            %   also the default if not supplied. Draft is always a
            %   positive number.
            %
            % 'Verbose' - logical flag (true/false), if true some text
            %   information about the mesh will be output to the command
            %   line. Default is false.
            % 
            % 'UseSTLName' - logical flag (true/false), if true the name
            %   stored in the stl file will be used as the body name. The
            %   old body name will be replaced with this name.
            %
            % 'CentreOfGravity' - 3 element vector with the x,y,z
            %   coordinates of the centre of gravity of the body in the stl
            %   file. If not supplied it is assumed that the mesh is drawn
            %   such that the centre of gravity is at the point (0,0,0) in
            %   the coordinate system of the stl file. The centre of
            %   gravity will be translated along with the mesh if it is
            %   translated to achieve a specified draft.
            %
            %
            % Output
            %
            %
            %
            % See Also: 
            %
            
            
            % 'PutCoGOnOrigin' - logical flag (true/false), if true the
            %   mesh will be translated (before applying the specified
            %   draft) such that the centre of gravity lies on the origin.
            %   This option is only really relevant if the
            %   'CentreOfGravity' option is used (see above). The purpose
            %   of this option is to deal with the case where an object has
            %   been created in some CAD program and it is more convenient
            %   to output the STL and centre of gravity of the shape in the
            %   CAD program's coordinate system than to move the shape in
            %   the CAD program before processing with NEMOH.
            
            options.Draft = [];
            options.Verbose = false;
            options.UseSTLName = false;
            options.CentreOfGravity = [];
%             options.PutCoGOnOrigin = false;
            
            options = parse_pv_pairs (options, varargin);
            
            % Input checking
            %
            % CentreOfGravity and Draft options are checked later by
            % the processMeshDraftAndCoG method
            self.checkLogicalScalar (options.UseSTLName, true, 'UseSTLName');
            self.checkLogicalScalar (options.Verbose, true, 'Verbose');
%             self.checkLogicalScalar (options.PutCoGOnOrigin, true, 'PutCoGOnOrigin');
            
            self.clearMeshAndForceData ();
            
            % only triangular stl meshes can imported currently
            [self.meshVertices, self.quadMesh, ~, stlname] = stl.read (filename);
            
            switch size (self.quadMesh, 2)
                
                case 3
                    % convert tri mesh to degenerate quad mesh by duplicating the
                    % final vertex
                    self.quadMesh = [self.quadMesh, self.quadMesh(:,end)];
                    
                case 4
                    % don't need to do anything
                    
                otherwise
                    
                    error ('STL import cannot handle the number of vertices in the faces of the mesh.');
                    
            end
            
            self.meshVertices = self.meshVertices.';
            self.quadMesh = self.quadMesh.';
            
            self.processMeshDraftAndCoG (options.Draft, options.CentreOfGravity);
            
            if options.UseSTLName
                self.setName (stlname);
            end
            
            self.nMeshNodes = size (self.meshVertices, 2);
            self.stlLoaded = true;
            self.meshType = 'nonaxi';
            self.meshPlottable = true;
            self.meshProcessed = false;
            
            self.calcMeshProps ();
            
            if options.Verbose
                self.meshInfo ();
            end
            
        end
        
        
        function addMeshDirect (self, vertices, faces, varargin)
            % directly supply a mesh made in matlab
            %
            % Syntax
            %
            % addMeshDirect (nb, vertices, faces)
            % addMeshDirect (..., 'Parameter', Value)
            %
            % Description
            %
            % Add a mesh specied in the native interface format to the
            % body. The native format is two matricies, one (3 x p)
            % containing the mesh vertices, the other (4 x q) containing
            % the quadrilateral information (which is indiexes into the
            % vertices matrix). See the descriptions of the 'vertices' and
            % 'faces' input arguments for more information.
            %
            % Input
            %
            %  nb - nemoh.body object 
            %
            %  vertices - (3 x p) matrix of 'p' vertices where each row 
            %   represents the x, y and z coordinate of each vertex. 
            %
            %  faces - (4 x q) matrix of 'q' vertex indices where each  
            %   column represents one quadrilateral in the mesh, and each
            %   row is the index of the column of the vertices matrix for
            %   each point in the quadrilateral.
            %
            % Addtional arguments may be supplied as parameter-value pairs.
            % The available options are:
            %
            %  'IsForAxiSim' - logical flag (true/false), if true indicates
            %    that the mesh is one suitible for an axisymetric
            %    simulation, and that an axisymmetric sim should be run.
            %    Default is false.
            %
            %  'Verbose' - logical flag (true/false), if true some text
            %    information about the mesh will be output to the command
            %    line. Default is false.
            %
            %
            % See Also: 
            %

%             options.NPanelsTarget = self.defaultTargetPanels;
            options.IsForAxiSim = false;
%             options.AddToExisting = false;
            options.Verbose = false;
            
            options = parse_pv_pairs (options, varargin);
            
            assert (size (vertices,1) == 3, 'vertices must be a 3 x n matrix');
            assert (size (faces,1) == 4, 'faces must be a 4 x n matrix');
%             assert (any (faces > size (vertices, 2), 'faces refers to vertices index greater than the size of vertices');

            faces = faces + size (self.meshVertices, 2);
            
            self.quadMesh = [self.quadMesh, faces];
            
            self.meshVertices = [ self.meshVertices, vertices];
            
            [Fc,Vc,ind1,ind2] = mergeVertices (self.quadMesh.', self.meshVertices.', 10);
            
            self.quadMesh = Fc.';
            self.meshVertices = Vc.';
            
            self.nMeshNodes = size (self.meshVertices, 2);
            self.nQuads = size (self.quadMesh, 2);
            
            if options.Verbose
                self.meshInfo ();
            end
            
            if options.IsForAxiSim
                self.meshType = 'axi';
            else
                self.meshType = 'nonaxi';
            end
            self.meshPlottable = true;
            
            self.calcMeshProps ();
            
        end
        
        function makeAxiSymmetricMesh (self, r, z, ntheta, zCoG, varargin)
            % initialise a mesh based on a 2D profile rotated around z axis
            %
            % Syntax
            %
            % makeAxiSymmetricMesh (nb, r, z, ntheta, zCoG)
            % makeAxiSymmetricMesh (..., 'Parameter', value)
            %
            % Description
            %
            % makeAxiSymmetricMesh initialises a 3D mesh of an axisymmetric
            % body described using a 2D profile in the (r,z) plane, defined
            % using cylindrical coordinates (r,theta,z). The 3D shape is
            % the profile swept out when the profile is rotated around the
            % z axis The shape is rotated only 180 degrees as NEMOH is able
            % to take advantage of the shape's symmetry.
            %
            % Note that the profile must be created starting from the
            % topmost point to ensure the faces point outward as required
            % by NEMOH.
            %
            % Once created, the mesh must be refined using the NEMOH
            % meshing program. This is done by frst writing the basic mesh
            % description to disk using writeMesh, and then calling
            % processMesh to run the NEMOH mesing program on the input
            % files and load the results.
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            %  r - vector of n radial positons of the profile points
            %
            %  z - vector of n axial positons of the profile points
            %
            %  ntheta - number of steps to rotate around the z axis
            %
            %  zCoG - vertical position of the centre of gravity of the
            %    body relative to the mean water level.
            %
            % Additional optional arguments may be supplied using
            % parameter-value pairs. The available options are:
            %
            %  'Verbose' - logical flag (true/false), if true some text
            %    information about the mesh will be output to the command
            %    line. Default is false.
            %
            %  'NPanelsTarget' - scalar target number of panels for the
            %    refined mesh Default is 250.
            %
            %
            
            options.Verbose = true;
            options.NPanelsTarget = self.defaultTargetPanels;
            options.AdvancedCricleMesh = true;
            options.IsForAxiSim = true;
            options.Theta = [];
            options.AddToExisting = false;
            
            options = parse_pv_pairs (options, varargin);
            
            if options.IsForAxiSim
                options.Theta = pi ();
            else
                if isempty (options.Theta)
                    options.Theta = 2* pi ();
                end
                self.checkNumericScalar (options.Theta, true, 'Theta (rotation sweep angle)');
                assert ( options.Theta > 0 && options.Theta <= 2*pi (), ...
                         'Theta must be > 0 and <= 2*pi' );
            end
            
            self.checkNumericScalar (zCoG, true, 'zCoG (Vertical Centre of Gravity)');
            self.checkLogicalScalar (options.AdvancedCricleMesh, true, 'AdvancedCricleMesh')
            
            self.nPanelsTarget = options.NPanelsTarget;
            
            if ~options.AddToExisting
                % clear any previous mesh and force data
                self.clearMeshAndForceData ();
            end
            
            % store profile for inspection later
            self.axiMeshR = r;
            self.axiMeshZ = z;
            
            n = numel (r);
            
            if numel (z) ~= n
                error ('Number of elements in r must be same as in z');
            end
            
            % TODO: calculate centre of gravity assuming uniform density if
            % it is not suplied
            self.centreOfGravity = [ 0; 0; zCoG ];
            
            ntheta = ntheta + ~iseven(ntheta);% Force even
            
            % discretisation angles
            theta = linspace (0., options.Theta, ntheta+3);
            
            self.nMeshNodes = 0;
            
            endn = n;
            numpoints = n;
            nskip = 1;
            
            nodeaddstart = 1;
            nodeaddend = n;
            
%             quadaddstart = 1;
            quadaddend = n - 1;
            
            if options.IsForAxiSim
                n_circ_theta = ntheta/2;
            else
                n_circ_theta = ntheta/4;
            end
            
            % Create the vertices
            if options.AdvancedCricleMesh && self.haveGIBBON && r(1) == 0
                % if the first point on the 2d curve is on the z axis, we
                % must skip it and add a special quad circle mesh 
                
                nodeaddstart = 2;
                quadaddend = quadaddend - 1;
                
                endn = n - 1;
                numpoints = n - 1;
                
                if z(1) > z(end)
                    revquads = false;
                else
                    revquads = true;
                end
                
                
                self.addCircleSurfMesh (r(2), z(1), z(2), n_circ_theta, options.IsForAxiSim, revquads);
                
            end
            
            if options.AdvancedCricleMesh && self.haveGIBBON && r(n) == 0
                
                nodeaddend = nodeaddend - 1;
                quadaddend = quadaddend - 1;
                endn = endn - 1;
                numpoints = numpoints - 1;
                
            end
            
            prevvertnunm = self.nMeshNodes;
            for j = 1:ntheta+3
                for i = nodeaddstart:nodeaddend
                    self.nMeshNodes = self.nMeshNodes + 1;
                    self.meshVertices(1, self.nMeshNodes) = r(i)*cos(theta(j));
                    self.meshVertices(2, self.nMeshNodes) = r(i)*sin(theta(j));
                    self.meshVertices(3, self.nMeshNodes) = z(i);
                end
            end

            % Make the other faces
            self.nQuads = size (self.quadMesh, 2);
           
            for i = 1:quadaddend
                for j = 1:ntheta+2
                    self.nQuads = self.nQuads + 1;
                    self.quadMesh(1,self.nQuads) = prevvertnunm+i+numpoints*(j-1);
                    self.quadMesh(2,self.nQuads) = prevvertnunm+1+i+numpoints*(j-1);
                    self.quadMesh(3,self.nQuads) = prevvertnunm+1+i+numpoints*j;
                    self.quadMesh(4,self.nQuads) = prevvertnunm+i+numpoints*j;
                end
            end

            % make the bottom/top
            if options.AdvancedCricleMesh && self.haveGIBBON && r(n) == 0
                
                if z(1) > z(end)
                    revquads = true;
                else
                    revquads = false;
                end
                
                self.addCircleSurfMesh (r(n-1), z(n), z(n-1),n_circ_theta, options.IsForAxiSim, revquads);
                
            end
            
            if options.Verbose
                self.meshInfo ();
            end
            
            if options.IsForAxiSim
                self.meshType = 'axi';
            else
                self.meshType = 'nonaxi';
            end
            self.meshPlottable = true;
            
            self.calcMeshProps ();
            
        end
        
        function makeCylinderMesh (self, radius, draft, height, varargin)
            % create a course mesh of a cylinder
            %
            % Syntax
            %
            %
            %
            % Description
            %
            % makeCylinderMesh creates a course cylinder mesh for the body
            % of a given radius. Being axisymmetric, only half the cylinder
            % is meshed, and only those portions piercing or under the mean
            % water surface.
            %
            % Input
            %
            %  radius - cylinder radius
            %
            %  draft - depth of base below mean water level (this is a
            %    positive number, the absolute depth)
            %
            %  height - cylinder height, used to determine if cylinder is
            %    surface piecing or not. Can be empty ([]) in which case
            %    the cylinder is assumed to be surface piercing. If height
            %    is not empty, and the optional VerticalCentreOfGravity
            %    argument is not used (see below), the cylinder is assumed
            %    to be of uniform density, and the vertical centre of mass
            %    is set to the position corresponding to half the height of
            %    the cylinder from its base at the given draft. If the
            %    height is empty, the VerticalCentreOfGravity options must
            %    be used.
            %
            % Additional optional arguments may be supplied using
            % parameter-value pairs. The available options are:
            %
            % 'NTheta' - The cylinder is created by rotating an 'L' shape 
            %   around the z axis. This option allows you to choose the
            %   number of rotational increments around z axis to create the
            %   (half) cylinder mesh. Default is 30 if not supplied.
            %
            % 'VerticalCentreOfGravity' - Vertical location of the
            %   cylinder's centre of mass relative to the mean water
            %   surface. You can alternatively specify the 'Height' option
            %   described below. If neither option is supplied, the
            %   vertical centre of mass is set to -draft/3.
            %
            % 'Verbose' - logical flag (true/false), if true some text
            %   information about the mesh will be output to the command
            %   line. Default is false.
            %
            % 'NPanelsTarget' - scalar target number of panels for the
            %   refined mesh Default is 250.
            %
            % Output
            %
            %  none
            %
            %
            % See Also: nemoh.body.makeAxiSymmetricMesh
            %

            options.NTheta = 30;
            options.VerticalCentreOfGravity = [];
            options.NPanelsTarget = 250;
            options.Verbose = false;
            
            options = parse_pv_pairs (options, varargin);
            
            assert (draft > 0, 'draft must be greater than zero');

            if isempty (height)
                
                self.checkNumericScalar (options.VerticalCentreOfGravity, true, 'VerticalCentreOfGravity');
                
                verticalCentreOfGravity = options.VerticalCentreOfGravity;
            else
                
                assert (height > 0, 'height must be greater than zero');
                
                if isempty (options.VerticalCentreOfGravity)
                    verticalCentreOfGravity = (height./2) - draft;
                else
                    self.checkNumericScalar (options.VerticalCentreOfGravity, true, 'VerticalCentreOfGravity');
                     
                    verticalCentreOfGravity = options.VerticalCentreOfGravity;
                end
            end
            
            if isempty (height)
                zcyl = -draft;
            elseif height > draft
                zcyl = -draft;
            else
                zcyl = height;
            end
            
            r = [radius,  radius,  0]; 
            z = [0,       zcyl,    zcyl];

            % define the body shape using a 2D profile rotated around the z axis
            self.makeAxiSymmetricMesh ( r, z, options.NTheta, verticalCentreOfGravity, ...
                            'NPanelsTarget', options.NPanelsTarget, ...
                            'Verbose', options.Verbose );
            
        end

        function makeSphereMesh (self, radius, draft, varargin)
            % create a course mesh of a sphere
            %
            % Syntax
            %
            %
            %
            % Description
            %
            % makeSphereMesh creates a course sphere mesh for the body
            % of a given radius. Being axisymmetric, only half the sphere
            % is meshed, and only those portions piercing or under the mean
            % water surface.
            %
            % Input
            %
            %  radius - sphere radius. If the optional
            %    VerticalCentreOfGravity argument is not used (see below),
            %    the sphere is assumed to be of uniform density, and the
            %    vertical centre of mass is set to the position
            %    corresponding to half the height of the sphere from its
            %    base at the given draft.
            %
            %  draft - depth of base below mean water level (this is a
            %    positive number, the absolute displacement of the mesh's
            %    lowest point from the mean water level)
            %
            % Additional optional arguments may be supplied using
            % parameter-value pairs. The available options are:
            %
            % 'NTheta' - The sphere is created by rotating a shape 
            %   around the z axis. This option allows you to choose the
            %   number of rotational increments around z axis to create the
            %   (half) sphere mesh. Default is 30 if not supplied.
            %
            % 'VerticalCentreOfGravity' - Vertical location of the
            %   cylinder's centre of mass relative to the mean water
            %   surface. If not supplied it is set to the centre of the
            %   sphere.
            %
            % 'NProfilePoints' - number of points with which to make the 2D
            %   profile which is rotated to create the mesh. The more
            %   points the closer to a circle. Default is 20.
            %
            % 'Verbose' - logical flag (true/false), if true some text
            %   information about the mesh will be output to the command
            %   line. Default is false.
            %
            % 'NPanelsTarget' - scalar target number of panels for the
            %   refined mesh Default is 250.
            %
            % Output
            %
            %  none
            %
            %
            % See Also: nemoh.body.makeAxiSymmetricMesh
            %

            options.NTheta = 30;
            options.VerticalCentreOfGravity = [];
            options.NProfilePoints = 20;
            options.NPanelsTarget = 250;
            options.Verbose = false;
            
            options = parse_pv_pairs (options, varargin);
            
            self.checkNumericScalar (draft, true, 'draft');
            self.checkNumericScalar (radius, true, 'radius');
            assert (draft > 0, 'draft must be greater than zero');
            assert (radius > 0, 'radius must be greater than zero');
            
            if 2*radius > draft
                % find angle where mean water height is on sphere
                z = (draft - radius);

                x = sqrt ( radius.^2  - z.^2 );

                [ ~, theta, ~ ] = cart2sph (0, x, z);

                theta = linspace ( -tau () ./ 4,  ...
                                   theta, ...
                                   options.NProfilePoints );
            else
                theta = linspace ( -tau () ./ 4,  ...
                                   tau () / 4, ...
                                   options.NProfilePoints );
            end
            
            [ x, y, z ] = sph2cart (0, theta, radius);
            
            [ ~, r, z] = cart2pol (x, y, z);
            
            % need to change order to get normals pointing the right
            % direction
            r = fliplr (r);
            z = fliplr (z);
            
            % shift the whole thing so top of mesh is at the mean water
            % surface
            z = z + radius - draft;
            
            if isempty (options.VerticalCentreOfGravity)
                verticalCentreOfGravity = radius - draft;
            else
                self.checkNumericScalar (options.VerticalCentreOfGravity, true, 'VerticalCentreOfGravity');
                verticalCentreOfGravity = options.VerticalCentreOfGravity;
            end

            % define the body shape using a 2D profile rotated around the z axis
            self.makeAxiSymmetricMesh (r, z, options.NTheta, verticalCentreOfGravity, ...
                            'NPanelsTarget', options.NPanelsTarget, ...
                            'Verbose', options.Verbose );
            
        end

        function [hmesh, hax, hfig] = drawMesh (self, varargin)
            % plot the mesh for this body
            %
            % Syntax
            %
            % drawMesh (nb)
            % drawMesh (nb, 'Parameter', value)
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            % Additional optional arguments are provided as parameter-value
            % pairs. The available options are:
            %
            % 'Axes' - handle for existing figure axes in which to do the
            %   mesh plot. f not supplied, a new figure and axes are
            %   created.
            %
            % 'PlotForces' - logical flag indiacting whether to plot the
            %   calculated hydrostatic forces if they are available.
            %   Default is true if not supplied.
            %
            % Output
            %
            %  None
            %
            %
            
            options.Axes = [];
            options.PlotForces = true;
            options.AddTitle = true;
            options.EdgeColor = [0, 0.7500, 0.7500];
            
            options = parse_pv_pairs (options, varargin);
            
            self.checkLogicalScalar (options.PlotForces, true, 'PlotForces');
            self.checkLogicalScalar (options.AddTitle, true, 'AddTitle');
            
            setequal = true;
            
            if self.meshPlottable == true
                
                if isempty (options.Axes)
                    hfig = figure;
                    hax = axes (hfig);
                    view (hax, 3);
                else
                    self.checkIsAxes (options.Axes, true);
                    hax = options.Axes;
                    hfig = get (hax, 'Parent');
                    % leave the axis as it is, don't mess with user's
                    % settings
                    setequal = false;
                end
                
                hold on;

                [hmesh, hax, hfig] = self.polyMeshPlot ( self.meshVertices', ...
                                                         self.quadMesh', ...
                                                         'Axes', hax, ...
                                                         'PatchParameters', {'edgecolor', options.EdgeColor} );
                                                     
                if ~isempty (self.centreOfGravity)
                    
                    % add centre of gravity
                    scatter3 ( hax, self.centreOfGravity(1), ...
                                    self.centreOfGravity(2), ...
                                    self.centreOfGravity(3), ...
                                    '+' );

                    % note we use the 'parent property rather than first
                    % argument as being the axes to create the text object in
                    % for Octave compatibility.
                    text ( self.centreOfGravity(1) + 0.01 * self.meshSize(1), ...
                           self.centreOfGravity(2) + 0.01 * self.meshSize(2), ...
                           self.centreOfGravity(3), ...
                           sprintf ('%s CoG', self.name), ...
                           'parent', hax );
                   
                end

                if self.meshProcessed && ~isempty (self.centreOfBuoyancy)
                    
                    % add centre of buoyancy
                    scatter3 ( hax, self.centreOfBuoyancy(1), ...
                                    self.centreOfBuoyancy(2), ...
                                    self.centreOfBuoyancy(3), ...
                                   '+' );

                    % note we use the 'parent property rather than first
                    % argument as being the axes to create the text object
                    % in for Octave compatibility.
                    text ( self.centreOfBuoyancy(1) + 0.01 * self.meshSize(1), ...
                           self.centreOfBuoyancy(2) + 0.01 * self.meshSize(2), ...
                           self.centreOfBuoyancy(3), ...
                           sprintf ('%s CoB', self.name), ...
                           'parent', hax );
                       
                end
                
                % plot forces if requested, and available
                if options.PlotForces && ~isempty (self.hydrostaticForces)
                    
                    quiver3 ( hax, ...
                              self.hydrostaticForcePoints(1,:), ...
                              self.hydrostaticForcePoints(2,:), ...
                              self.hydrostaticForcePoints(3,:), ...
                              self.hydrostaticForces(1,:), ...
                              self.hydrostaticForces(2,:), ...
                              self.hydrostaticForces(3,:), ...
                              'Color', [0,0.447,0.741] );
                    
                end
                
                hold off
                
                if options.AddTitle
                    title ('Mesh for NEMOH Body');
                end
                
                if setequal
                    axis equal;
                end
            
            else
                error ('body %s mesh is not available for plotting', self.uniqueName);
            end
            
        end
        
        function makeTriMeshFromQuads (self, varargin)
            % makes a triangle mesh by splitting each quad in the quad mesh
            
            options.CompleteAxiMesh = true;
            
            options = parse_pv_pairs (options, varargin);
            
            assert ( self.nQuads > 0 && size (self.quadMesh,2) > 0, ...
                     'There is no quad mesh to split into triangles (nQuads = %d, size (quadMesh,2) = %d, both must be greater than zero, and should be the same).', ...
                     self.nQuads, ...
                     size (self.quadMesh,2) );
                 
            
            if strcmp (self.meshType, 'axi') && options.CompleteAxiMesh
                
                % we rotate existing x and y coordinates around z axis by 180
                % degrees after undoing any mesh traslation which would
                % have moved the mesh from being axisymmetric around the
                % z axis. We then shift it back to the original location
                Xnew = (self.meshVertices(1,:) - self.meshTranslation(1))  * cos(pi) - (self.meshVertices(2,:) - self.meshTranslation(2)) * sin(pi);
                Xnew = Xnew + self.meshTranslation(1);
                
                Ynew = (self.meshVertices(1,:) - self.meshTranslation(1)) * sin(pi) +  (self.meshVertices(2,:) - self.meshTranslation(2)) * cos(pi);
                Ynew = Ynew + self.meshTranslation(2);
                
                new_verts_startind = size (self.meshVertices, 2);
                
                self.triMeshVertices = [ self.meshVertices, ...
                                         [ Xnew;
                                           Ynew;
                                           self.meshVertices(3,:) ]; ...
                                       ];
                                   
                self.triMesh = [ self.quadMesh(1:3,:), ...
                                 [ self.quadMesh(3,:);
                                   self.quadMesh(4,:);
                                   self.quadMesh(1,:) ] ...
                                 self.quadMesh(1:3,:) + new_verts_startind, ...
                                 [ self.quadMesh(3,:);
                                   self.quadMesh(4,:);
                                   self.quadMesh(1,:) ] + new_verts_startind ...
                               ];
                
            else
                self.triMeshVertices = self.meshVertices;
                
                self.triMesh = [ self.quadMesh(1:3,:), ...
                                 [ self.quadMesh(3,:);
                                   self.quadMesh(4,:);
                                   self.quadMesh(1,:) ] ...
                                ];
                
            end
            

            
        end
        
        function [hmesh, hax, hfig] = drawTriMesh (self, varargin)
            
            options.Axes = [];
            options.PlotForces = true;
            options.AddTitle = true;
            
            options = parse_pv_pairs (options, varargin);
            
            setequal = true;
            if isempty (options.Axes)
                hfig = figure;
                hax = axes (hfig);
                view (hax, 3);
            else
                self.checkIsAxes (options.Axes, true);
                hax = options.Axes;
                hfig = get (hax, 'Parent');
                % leave the axis as it is, don't mess with user's
                % settings
                setequal = false;
            end
            
            assert ( size (self.triMesh,2) > 0, ...
                     'There is no triangle mesh to draw (size (triMesh,2) = %d), have you called makeTriMeshFromQuads?', ...
                     self.nQuads, ...
                     size (self.quadMesh,2) );
                 
            [hmesh, hax, hfig] = self.polyMeshPlot ( self.triMeshVertices', ...
                                                     self.triMesh', ...
                                                     'Axes', hax );
                                                 
            if options.AddTitle
                title ('Mesh for NEMOH Body');
            end

            if setequal
                axis equal;
            end
        end
        
        function writeSTL (self, filename, varargin)
            % writes a triangle mesh of the body to an STL file
            %
            % Syntax
            %
            % nemoh.body.writeSTL (bd, filename)
            % nemoh.body.writeSTL (..., 'Parameter', Value)
            %
            % Description
            %
            % writeSTL creates an triangle STL file from the mesh. It does
            % this by splitting quads in half. If the mesh is an
            % axismmetric mesh it is by default completed into a full 360
            % degree sweep before writing to the STL. By default the mesh
            % is also translated such that the centre of gravity of the
            % body lies at (0,0). This is done as this is how the time
            % domain EWST solver expects it to be defined. Both of these
            % defaults can be changed using optional parameters described
            % below.
            %
            % Internally if the body's triMesh property is empty, writeSTL
            % calls makeTriMeshFromQuads to create it, so the triangle
            % mesh, before centre of gravity adjustment, is stored in the
            % triMesh property and can be plotted with drawTriMesh. If
            % triMesh is already populated, writeSTL doesn't call it again,
            % but uses the existing mesh.
            %
            % Input
            %
            %  bd - nemoh.body object
            %
            %  filename - fill path to the stl file to be created
            %
            % Addtional arguments may be supplied as parameter-value pairs.
            % The available options are:
            %
            %  'ShiftCoGToOrigin' - true/false flag indicating whether the
            %    mesh written to the STL file will be translated such that
            %    th body centre of gravity lies on the origin (0,0).
            %    Default is true.
            %
            %  'CompleteAxiMesh' - true/false flag indicating whether
            %    axisymmetric meshes which by default are only a half mesh
            %    will be converted to a full mesh when exported to STL.
            %

            options.ShiftCoGToOrigin = true;
            options.CompleteAxiMesh = true;
            
            options = parse_pv_pairs (options, varargin);
            
            check.isLogicalScalar (options.ShiftCoGToOrigin, true, 'ShiftCoGToOrigin');
            
            if size (self.triMesh,2) < 1
                % attmept to make the triangle mesh if it doesn't exist yet
                self.makeTriMeshFromQuads ('CompleteAxiMesh', options.CompleteAxiMesh);
            end

               
            % write the stl file
            if options.ShiftCoGToOrigin
                stl.write (filename, self.triMesh.', self.triMeshVertices.' - self.centreOfGravity.');
            else
                stl.write (filename, self.triMesh.', self.triMeshVertices.');
            end
            
        end
        
        function writeMesh (self, varargin)
            % write the mesh description to disk (if necessary)
            
            % TODO: help for writeMesh
            
            options.MeshFileName = sprintf ('%s.dat', self.uniqueName);
            options.TargetPanels = [];
            
            options = parse_pv_pairs (options, varargin);
            
            if ~isempty (options.TargetPanels)
                self.checkScalarInteger (options.TargetPanels, true, 'TargetPanels');
            end
            
            switch self.meshType
                
                case {'axi', 'nonaxi'}
                    
                    self.writeMesherInputFile ( 'MeshFileName', options.MeshFileName, ...
                                                'TargetPanels', options.TargetPanels );
                    
                otherwise
                    error ('mesh type %s not currently supported', self.meshType)
                    
            end
        end
        
        function meshInfo (self)
            % print some information about the nemoh mesh
            
            fprintf('\n Characteristics of the mesh for NEMOH \n');
            fprintf('\n --> Number of nodes : %g', self.nMeshNodes);
            fprintf('\n --> Number of panels : %g\n \n', self.nQuads);
            
        end
        
        function processMesh (self, varargin)
            % runs the NEMOH 'mesh' program on the mesh and loads results
            %
            % Syntax
            %
            % processMesh (nb)
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            % Additional optional arguments are provided as parameter-value
            % pairs. The available options are:
            %
            % 'LoadMesh' - logical (true/false) value. If true, the
            %   existing mesh data is cleared and the processed mesh is
            %   loaded from disk after processing the mesh. Default is
            %   false.
            %
            % 'LoadMeshData' - logical (true/false) value. If true, the
            %   calulated body properties are loaded from disk after
            %   processing the mesh. The data loaded is the displacement,
            %   buoyancy center, hydrostatic stiffness, an estimate of the
            %   masses and the inertia matrix. These results are then
            %   accessible via the body properties kH,
            %   hydrostaticForcePoints, hydrostaticForces,
            %   centreOfBuoyancy, mass, WPA and inertia. Default is false.
            %
            % See also: nemoh.body.loadProcessedMesh,
            %           nemoh.body.loadProcessedMeshData
            %
            
            options.LoadMesh = true;
            options.LoadMeshData = true;
            
            options = parse_pv_pairs (options, varargin);
            
            self.checkLogicalScalar (options.LoadMesh, true, 'LoadMesh');
            self.checkLogicalScalar (options.LoadMeshData, true, 'LoadMeshData');
            
            if self.meshProcessed
                warning ('Processing mesh for body with meshProcessed == true');
            end
            
            logfile = fullfile (self.meshDirectory, sprintf ('mesh_%s.log', self.uniqueName));
            
            % change directory to directory above mesh directory and Nemo
            % mesh programs can't take a file input and just looks for
            % field in current directory (FFS!). onCleanup is used to
            % restore the current directory when we're done
            CC = onCleanup (@() cd (pwd ()));
            cd (self.meshInputDirectory);
            
            if isoctave ()
                [status, result] = system (sprintf ('"%s" > "%s"', self.meshProgPath, logfile));
            else
                [status, result] = cleansystem (sprintf ('"%s" > "%s"', self.meshProgPath, logfile));
            end
            
            if status ~= 0
                error ('mesh processing failed with error code %d and messge: "%s"', status, result);
            end

            % move the mesh file to the top level input directory for NEMOH
            movefile (self.meshFilePath, self.inputDataDirectory);
            
            self.meshProcessed = true;
            
            if options.LoadMesh
                self.loadProcessedMeshAndForces ();
            end
            
            if options.LoadMeshData
                self.loadProcessedMeshData ();
            end

        end
        
        function loadProcessedMeshAndForces (self)
            % loads the results of running the NEMOH mesh program
            %
            % Syntax
            %
            % loadProcessedMeshAndForces (nb)
            %
            % Description
            %
            % Loads the output of the NEMOH mesh (or Mesh.exe) program from
            % the produced .tec file. The existing mesh and results are
            % cleared. The mesh and hydrostatic force results are then
            % repopulated with the data from the file.
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            % Output
            %
            %  none
            %
            % See Also: nemoh.body.processMesh
            %
            
            if self.meshProcessed
                
                % clear mesh and force data (don't use
                % clearMeshAndForceData as it also resets other things)
                % mesh data
                self.axiMeshR = [];
                self.axiMeshZ = [];
                self.meshVertices = [];
                self.quadMesh = [];
                self.nMeshNodes = [];
                self.nQuads = [];

                % mesh results
                self.hydrostaticForces = [];
                self.hydrostaticForcePoints = [];
                self.centreOfBuoyancy = [];
                self.WPA = [];
                self.mass = [];
                self.inertia = [];
                self.kH = [];

                % Load from mesh visualisation .tec file
                fid = fopen (fullfile (self.meshDirectory, sprintf ('%s.tec', self.uniqueName)), 'r');
                CC = onCleanup (@() fclose (fid));

                line = fscanf (fid, '%s', 2); % what does this line do?

                self.nMeshNodes = fscanf (fid, '%g', 1);

                line = fscanf(fid, '%s', 2); % what does this line do?

                self.nQuads = fscanf(fid, '%g', 1);

                line = fgetl (fid); % what does this line do?

                self.meshVertices = ones (3, self.nMeshNodes) * nan;
                for i = 1:self.nMeshNodes
                    line = fscanf (fid, '%f', 6);
                    self.meshVertices(1,i) = line(1);
                    self.meshVertices(2,i) = line(2);
                    self.meshVertices(3,i) = line(3);
                end

                self.quadMesh = ones (4, self.nQuads) * nan;
                for i = 1:self.nQuads
                    line = fscanf(fid, '%g', 4);
                    self.quadMesh(1,i) = line(1);
                    self.quadMesh(2,i) = line(2);
                    self.quadMesh(3,i) = line(3);
                    self.quadMesh(4,i) = line(4);
                end 

                line = fgetl (fid);
                line = fgetl (fid);

                for i = 1:self.nQuads
                    line = fscanf (fid,'%g %g',6);
                    self.hydrostaticForcePoints(1,i) = line(1);
                    self.hydrostaticForcePoints(2,i) = line(2);
                    self.hydrostaticForcePoints(3,i) = line(3);
                    self.hydrostaticForces(1,i) = line(4);
                    self.hydrostaticForces(2,i) = line(5);
                    self.hydrostaticForces(3,i) = line(6);
                end
                
                self.calcMeshProps ();
            
            else
                error ('Mesh is not marked as ''processed''');
            end
            
        end
        
        function loadNemohMeshFile (self, filename, varargin)
            % clear existing mesh and load mesh from generated .dat file
            %
            % Syntax
            %
            % loadNemohMeshFile (nb, filename)
            % loadNemohMeshFile (..., 'Parameter', value)
            %
            % Description
            %
            % loadNemohMeshFile imports a mesh from a nemoh mesh input
            % file, i.e. with the format expected by the Nemoh preprocessor
            % and solver, as produced by the Nemoh mesh (or Mesh.exe)
            % program.
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            %  filename - nemoh mesher input file name
            %
            % Additional optional arguments may be supplied using
            % parameter-value pairs. The available options are:
            %
            % 'Draft' - distance from the lowest point on the mesh to the
            %   water free surface. The mesh will be translated such that
            %   the specified draft is achieved. If Draft is empty the
            %   displacement is kept as it is in the mesh file. This is
            %   also the default if not supplied. Draft is always a
            %   positive number.
            %
            % 'CentreOfGravity' - 3 x 1 element column vector with the 
            %   x,y,z coordinates of the centre of gravity of the body in
            %   the stl file. If not supplied it is assumed that the mesh
            %   is drawn such that the centre of gravity is at the point
            %   (0,0,0) in the coordinate system of the stl file. The
            %   centre of gravity will be translated along with the mesh if
            %   it is translated to achieve a specified draft.
            %
            % 'Verbose' - logical flag (true/false), if true some text
            %   information about the mesh will be output to the command
            %   line. Default is false.
            %
            
            options.Draft = [];
            options.Verbose = false;
            options.CentreOfGravity = [];
            
            options = parse_pv_pairs (options, varargin);
            
            self.checkLogicalScalar (options.Verbose, true, 'Verbose');
            
            
            self.clearMeshAndForceData ();
            
            % Mesh file
            fid = fopen (filename, 'r');
            % ensure file is closed when done or on failure
            CC = onCleanup (@() fclose (fid));

            % first line is the number 2, then 1 or 0 indicating whether
            % this is an axisymmetric mesh
            headerdata = fscanf (fid, '%d', 2);
            
            if headerdata(2) == 0
                self.meshType = 'nonaxi';
            elseif headerdata(2) == 1
                self.meshType = 'axi';
            else
                error ('Could not load mesh type from NEMOH input mesh file, was not 0 or 1.');
            end
            
            % TODO: better to do a first pass to count nodes and faces then preallocate
            vertexind = 1;
            vertexdata = fscanf (fid, '%f', 4);
            while vertexdata(1) ~= 0
                self.meshVertices(1,vertexind) = vertexdata(2);
                self.meshVertices(2,vertexind) = vertexdata(3);
                self.meshVertices(3,vertexind) = vertexdata(4);
                vertexdata = fscanf (fid, '%f', 4);
                vertexind = vertexind + 1;
            end
            
            faceind = 1;
            facedata = fscanf (fid, '%f', 4);
            while facedata(1) ~= 0
                self.quadMesh(1,faceind) = facedata(1);
                self.quadMesh(2,faceind) = facedata(2);
                self.quadMesh(3,faceind) = facedata(3);
                self.quadMesh(4,faceind) = facedata(4);
                facedata = fscanf (fid, '%f', 4);
                faceind = faceind + 1;
            end
            
            self.nMeshNodes = size (self.meshVertices, 2);
            self.nQuads = size (self.quadMesh, 2);
            
            self.processMeshDraftAndCoG (options.Draft, options.CentreOfGravity);
            
            self.meshPlottable = true;
            self.calcMeshProps ();
            
        end
        
        function translateMesh (self, x, y)
            % translate the mesh vertex locations in X-Y plane
            %
            % Syntax
            %
            % translateMesh (nb, x, y)
            %
            % Description
            %
            % translateMesh translates a mesh by adding a displacement in x
            % and y to every mesh vertex location.
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            %  x - displacement in x direction
            %
            %  y - displacement in y direction
            %
            
            self.checkNumericScalar (x, true, 'x');
            self.checkNumericScalar (y, true, 'y');
            
            assert (~isempty (self.meshVertices), ...
                'Mesh does not appear to be loaded yet (meshVertices is empty).');
            
            self.meshVertices = bsxfun (@plus, self.meshVertices, [x; y; 0]);
            
            % keep track of translation so we can undo it if necessary
            % (e.g. when making a tiangle mesh of an axi mesh)
            self.meshTranslation = self.meshTranslation + [x; y; 0];
            
        end
        
        function scaleMesh (self, scale_factor, varargin)
            % scale the mesh vertex locations by a given factor
            %
            % Syntax
            %
            % scaleMesh (nb, scale_factor)
            %
            % Description
            %
            % scaleMesh scales a mesh by multiplying every value of the
            % vertices by a constant scale factor. 
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            %  scale_factor - factor by which to scale the mesh vertex
            %    locations
            %
            % Additional options may be supplied as parameter-value pairs.
            % The available options are:
            %
            %  'ScaleCoG' - true/false flag indicating whether to also
            %    scale the centre of gravity of the mesh. Default is true.
            %    This option is ignored if the CentreOfGravity option is
            %    used (see below) to specify directly the new centre of
            %    gravity.
            %
            %  'CentreOfGravity' - option to specify directly the new
            %    centre of gravity.  Should be a 3 element numeric vector.
            %    If this option is used, the ScaleCoG option is ignored.
            %
            %
            
            options.ScaleCoG = true;
            options.CentreOfGravity = [];
            
            options = parse_pv_pairs (options, varargin);
            
            self.checkLogicalScalar (options.ScaleCoG, true, 'ScaleCoG');
            
            assert (~isempty (self.meshVertices), ...
                'Mesh does not appear to be loaded yet (meshVertices is empty).');

            self.meshVertices = self.meshVertices .* scale_factor;
            
            if isempty (options.CentreOfGravity)
                if options.ScaleCoG
                    cog = self.centreOfGravity .* scale_factor;
                end
            else
                cog = options.CentreOfGravity;
            end
            
            self.processMeshDraftAndCoG ([], cog);
            
            % force recalculation of mesh stuff as we have modified the
            % mesh
            self.meshProcessed = false;
            self.hydrostaticForces = [];
            self.hydrostaticForcePoints = [];
            self.centreOfBuoyancy = [];
            self.WPA = [];
            self.mass = [];
            self.inertia = [];
            self.kH = [];
            
            self.calcMeshProps ();
            
        end
        
        function loadNemohMesherInputFile (self, filename, meshcalfile, varargin)
            % load NEMOH mesher input file
            %
            % Syntax
            %
            % loadNemohMesherInputFile (nb, filename)
            % loadNemohMesherInputFile (..., 'Parameter', value)
            %
            % Description
            %
            % loadNemohMesherInputFile imports a mesh from an a nemoh
            % mesher input file, i.e. with the format expected by the Nemoh
            % mesh (or Mesh.exe) program.
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            %  filename - nemoh mesher input file name
            %
            % Additional optional arguments may be supplied using
            % parameter-value pairs. The available options are:
            %
            % 'Verbose' - logical flag (true/false), if true some text
            %   information about the mesh will be output to the command
            %   line. Default is false.
            %
            %
            
            % 'Draft' - distance from the lowest point on the mesh to the
            %   water free surface. The mesh will be translated such that
            %   the specified draft is achieved. If Draft is empty the
            %   displacement is kept as it is in the mesh file. This is
            %   also the default if not supplied. Draft is always a
            %   positive number.
            %
            % 'CentreOfGravity' - 3 element vector with the x,y,z
            %   coordinates of the centre of gravity of the body in the stl
            %   file. If not supplied it is assumed that the mesh is drawn
            %   such that the centre of gravity is at the point (0,0,0) in
            %   the coordinate system of the stl file. The centre of
            %   gravity will be translated along with the mesh if it is
            %   translated to achieve a specified draft.
            %
            
            options.Draft = [];
            options.Verbose = false;
            options.CentreOfGravity = [];
            options.TargetNumberOfPanels = [];
            
            options = parse_pv_pairs (options, varargin);
            
            self.checkLogicalScalar (options.Verbose, true, 'Verbose');
            
            self.clearMeshAndForceData ();
            
            % Mesh.cal file
            fid = fopen (meshcalfile, 'r');
            % ensure file is closed when done or on failure
            CC = onCleanup (@() fclose (fid));
            
            line = fgetl (fid);
            
            bodyname = strtrim (line);
            
            data = fscanf (fid, '%d', 1);
            
            if data == 0
                self.meshType = 'nonaxi';
            elseif data == 1
                self.meshType = 'axi';
            else
                error ('Unexpected value when reading axi/nonaxi value from Mesh.cal');
            end
            
            % Possible translation about x axis (first number) and y axis (second number)
            data = fscanf (fid, '%f', 2);
            
            self.centreOfGravity =  fscanf (fid, '%f', 3);
            % ensure it is a column vector
            self.centreOfGravity = self.centreOfGravity(:);
            
            self.defaultTargetPanels =  fscanf (fid, '%d', 1);
            
            clear CC
            
            if ~isempty (options.TargetNumberOfPanels)
                % replace loaded panels target with user specified
                self.checkScalarInteger (options.TargetNumberOfPanels, true, 'TargetNumberOfPanels');
                
                self.defaultTargetPanels = options.TargetNumberOfPanels;
                
            end
            
            self.nPanelsTarget = self.defaultTargetPanels;
            
            % Mesh file
            fid = fopen (filename, 'r');
            % ensure file is closed when done or on failure
            CC = onCleanup (@() fclose (fid));
            
            self.nMeshNodes = fscanf (fid, '%d', 1);
            
            self.nQuads = fscanf(fid, '%d', 1);
            
            self.meshVertices = ones (3,self.nMeshNodes) * nan;
            for i = 1:self.nMeshNodes
                line = fscanf (fid, '%f', 3);
                self.meshVertices(1,i) = line(1);
                self.meshVertices(2,i) = line(2);
                self.meshVertices(3,i) = line(3);
            end
            
            self.quadMesh = ones (4, self.nQuads) * nan;
            for i = 1:self.nQuads
                line = fscanf (fid, '%g', 4);
                self.quadMesh(1,i) = line(1);
                self.quadMesh(2,i) = line(2);
                self.quadMesh(3,i) = line(3);
                self.quadMesh(4,i) = line(4);
            end
            
%             self.processMeshDraftAndCoG (options.Draft, options.CentreOfGravity);
            
            self.meshPlottable = true;
            self.calcMeshProps ();
            
        end
        
        function loadProcessedMeshData (self)
            % load the non-mesh data calculated by mesher
            %
            % Syntax
            %
            % loadProcessedMeshData (nb)
            %
            % Description
            %
            % Loads the data created by the NEMOH mesh program in the
            % KH.dat, Hydrostatics.dat and Inertia_hull.dat files. From
            % these files, the following properties of the body object are
            % populated: kH, centreOfBuoyancy, mass, WPA, and inertia
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            %
            
            if self.meshProcessed
                
                self.kH = zeros(6,6);
                fid = fopen (fullfile (self.meshDirectory, 'KH.dat'), 'r');
                CC = onCleanup (@() fclose (fid));
                
                for i = 1:6
                    line = fscanf (fid,'%g %g',6);
                    self.kH(i,:) = line;
                end

                % load hydrostatics data
                fid = fopen (fullfile (self.meshDirectory, 'Hydrostatics.dat'),'r');
                CC = onCleanup (@() fclose (fid));
                
                line = fscanf (fid, '%s', 2);
                [tmp, count] = fscanf (fid, '%f', 1);
                if count == 1
                    self.centreOfBuoyancy(1,1) = tmp;
                else
                    self.centreOfBuoyancy(1,1) = nan;
                    warning ('Centre of buoyancy in X could not be read from Nemoh processed mesh output. centreOfBuoyancy(3,1) will be nan');
                end

                line = fgetl (fid);
                line = fscanf (fid,'%s',2);
                [tmp, count] = fscanf (fid, '%f', 1);
                if count == 1
                    self.centreOfBuoyancy(2,1) = tmp;
                else
                    self.centreOfBuoyancy(2,1) = nan;
                    warning ('Centre of buoyancy in Y could not be read from Nemoh processed mesh output. centreOfBuoyancy(3,1) will be nan');
                end

                line = fgetl (fid);
                line = fscanf (fid,'%s',2);
                [tmp, count] = fscanf (fid, '%f', 1);
                if count == 1
                    self.centreOfBuoyancy(3,1) = tmp;
                else
                    self.centreOfBuoyancy(3,1) = nan;
                    warning ('Centre of buoyancy in Z could not be read from Nemoh processed mesh output. centreOfBuoyancy(3,1) will be nan');
                end
                
                line = fgetl (fid);
                line = fscanf (fid,'%s',2);
                [tmp, count] = fscanf (fid,'%f',1);
                if count == 1
                    self.volume = tmp;
                else
                    self.volume = nan;
                    warning ('Volume could not be read from Nemoh processed mesh output. ''volume'' property will be nan (''mass'' will also be nan)');
                end
                self.mass = self.volume * self.rho;

                line = fgetl (fid);
                line = fscanf (fid,'%s',2);
                self.WPA = fscanf (fid,'%f',1);

                % load Inertia data
                self.inertia = zeros (6,6);
                fid = fopen (fullfile (self.meshDirectory, 'Inertia_hull.dat'),'r');
                CC = onCleanup (@() fclose (fid));
                
                for i = 1:3
                    line = fscanf (fid,'%g %g',3);
                    self.inertia(i+3,4:6) = line;
                end

                self.inertia(1,1) = self.mass;
                self.inertia(2,2) = self.mass;
                self.inertia(3,3) = self.mass;
            
            else
                error ('Mesh has not yet been processed, results not available')
            end
            
        end
        
        function str = generateBodyStr (self)
            % generates str describing body for NEMOH.cal input file
            %
            % Description
            %
            % generateBodyStr generates a string for this body which
            % represetents a section of a NEMOH input file. The NEMOH.cal
            % input file has a section describing the bodies to be
            % analysed, this string is the description of this body for
            % that section. generateBodyStr is intended to be used by the
            % writeNEMOH method of the nemoh.simulation class which
            % generates the full NEMOH input file.
            %
            % Syntax
            %
            % str = generateBodyStr (self)
            %
            % Output
            %
            %  str - string representing this body as it would be described
            %    in the bodies section of a NEMOH.cal input file
            %
            %
            
            if ischar (self.degreesOfFreedom)
               
                switch self.degreesOfFreedom
                    
                    case 'default'
                         self.degreesOfFreedom = { nemoh.translationalDoF([1,0,0]), ...
                                                   nemoh.translationalDoF([0,1,0]), ...
                                                   nemoh.translationalDoF([0,0,1]), ...
                                                   nemoh.rotationalDoF([1,0,0], self.centreOfGravity ), ...
                                                   nemoh.rotationalDoF([0,1,0], self.centreOfGravity ), ...
                                                   nemoh.rotationalDoF([0,0,1], self.centreOfGravity ) };
                                     
                    case 'none'
                        
                        self.degreesOfFreedom = {};
                        
                    otherwise
                        
                        error ('Invalid value in degreesOfFreedom property');
                        
                end
                
            end
            
            if self.meshProcessed
            
                str = sprintf ('%s\t\t! Name of mesh file\n', self.meshFileName);            
                str = sprintf ('%s%g %g\t\t\t! Number of points and number of panels \t\n', str, self.nMeshNodes, self.nQuads);

                % Degrees of freedom
                str = sprintf ('%s%d\t\t\t\t! Number of degrees of freedom\n', str, numel (self.degreesOfFreedom));
                
                for ind = 1:numel (self.degreesOfFreedom)
                    str = sprintf ('%s%s', str, self.degreesOfFreedom{ind}.generateDoFStr ());
                end

                % Resulting forces
                str = sprintf ('%s6\t\t\t\t! Number of resulting generalised forces\n', str);
                str = sprintf ('%s1 1. 0. 0. 0. 0. 0.\t\t! Force in x direction\n', str);
                str = sprintf ('%s1 0. 1. 0. 0. 0. 0.\t\t! Force in y direction\n', str);
                str = sprintf ('%s1 0. 0. 1. 0. 0. 0.\t\t! Force in z direction\n', str);
                str = sprintf ('%s2 1. 0. 0. %s %s %s\t\t! Moment force in x direction about a point\n', str, ...
                    self.formatNumber (self.centreOfGravity(1)), self.formatNumber (self.centreOfGravity(2)), self.formatNumber (self.centreOfGravity(3)));
                str = sprintf ('%s2 0. 1. 0. %s %s %s\t\t! Moment force in y direction about a point\n', str, ...
                    self.formatNumber (self.centreOfGravity(1)), self.formatNumber (self.centreOfGravity(2)), self.formatNumber (self.centreOfGravity(3)));
                str = sprintf ('%s2 0. 0. 1. %s %s %s\t\t! Moment force in z direction about a point\n', str, ...
                    self.formatNumber (self.centreOfGravity(1)), self.formatNumber (self.centreOfGravity(2)), self.formatNumber (self.centreOfGravity(3)));
                str = sprintf ('%s0\t\t\t\t! Number of lines of additional information \n', str);
            
            else
                error ('Body cannot generate NEMOH file contents as mesh has not been processed yet (need to call processMesh).');
            end
            
        end
        
    end
    
    methods (Access = private)
        
        function setupMeshDirectories (self, varargin)
            % initialise the mesh directories
            
            options.MeshFileName = sprintf ('%s.dat', self.uniqueName);
            
            options = parse_pv_pairs (options, varargin);
            
            self.meshFileName = options.MeshFileName;
            self.meshInputDirectory = fullfile (self.inputDataDirectory, sprintf ('mesh_input_for_%s', self.uniqueName));
            self.meshDirectory = fullfile (self.meshInputDirectory, 'mesh');
            self.meshFilePath = fullfile (self.meshDirectory, self.meshFileName );
            
            mkdir (self.inputDataDirectory);
            mkdir (self.meshInputDirectory);
            mkdir (self.meshDirectory);
%             mkdir (fullfile (self.inputDataDirectory, 'results'));
            
        end
        
        function writeMesherInputFile (self, varargin)
            % writes nemoh mesher input files for a body
            %
            % Description
            %
            % writeMeshInputCommon is a common function for generating the
            % mesh input file.
            %
            % Syntax
            %
            % writeMeshInputCommon (nb, 'Parameter', Value)
            %
            % Input
            %
            %  nb - nemoh.body object
            %
            % Additional optional inputs may be provided through
            % parameter-value pairs. The available options are:
            %
            % 'MeshFileName' - string containing the name of the input mesh
            %   file for NEMOH. If not supplied a file name is generated
            %   from the body's id property, i.e. body_<id>.dat
            %
            %
            
            options.MeshFileName = sprintf ('%s.dat', self.uniqueName);
            options.TargetPanels = [];
            
            options = parse_pv_pairs (options, varargin);
            
            if ~isempty (options.TargetPanels)
                
                self.checkScalarInteger (options.TargetPanels, true, 'TargetPanels');
                
                self.nPanelsTarget = options.TargetPanels;
                
            end
            
            self.setupMeshDirectories ('MeshFileName', options.MeshFileName);
            
            % Create mesh calculation files (input to mesh program)
            fid = fopen(fullfile (self.meshInputDirectory, 'Mesh.cal'), 'w');
            % ensure file is closed when done or on failure
            CC = onCleanup (@() fclose (fid));
            
            fprintf (fid, '%s\n', self.meshFileName(1:end-4));
            
            switch self.meshType
                
                case 'axi'
                    isaxi = true;
                case 'nonaxi'
                    isaxi = false;
                otherwise
                    error ('Body has mesh type %s, which is not currently able to be used to generate a Nemoh mesher input file.', ...
                        self.meshType );
            end
            
            % 1 if a symmetry about (xOz) is used. 0 otherwise
            fprintf (fid, '%d \n', double (isaxi));
            
            % Possible translation about x axis (first number) and y axis (second number)
            fprintf (fid, '0. 0. \n');

            % Coordinates of gravity centre
            fprintf (fid, '%s %s %s \n', ...
                self.formatNumber (self.centreOfGravity(1)), ...
                self.formatNumber (self.centreOfGravity(2)), ...
                self.formatNumber (self.centreOfGravity(3)) );

            % Target for the number of panels in refined mesh
            fprintf (fid, '%d \n', self.nPanelsTarget);
            
            % not documented
            fprintf (fid, '2 \n');
            
            % not documented
            fprintf (fid, '0. \n');
            
            % not documented
            fprintf (fid, '1.\n');
            
            % fluid density and gravity
            fprintf (fid, '%s \n%s \n', ...
                self.formatNumber (self.rho), self.formatNumber (self.g));
            
            % ID.dat file: This file is used for identifying the
            % calculation. It must be located in the working folder where
            % the codes are run. Second line is a string of characters. It
            % is the name of the working folder. First line is the length
            % of this string.
            fid = fopen (fullfile (self.meshInputDirectory, 'ID.dat'), 'w');
            % ensure file is closed when done or on failure
            CC = onCleanup (@() fclose (fid));
            
            fprintf (fid, '%d\n%s\n', 1, '.');
            
            % mesh course input file, for meshing program, not the same as
            % .dat actual mesh file for NEMOH
            fid = fopen(self.meshFilePath(1:end-4), 'w');
            % ensure file is closed when done or on failure
            CC = onCleanup (@() fclose (fid)); 
            
            fprintf (fid, '%g \n', self.nMeshNodes);
            
            fprintf (fid, '%g \n', self.nQuads);
            
            for i = 1:self.nMeshNodes
                fprintf (fid, '%E %E %E \n', self.meshVertices(1,i), self.meshVertices(2,i), self.meshVertices(3,i));
            end
            
            for i = 1:self.nQuads
                fprintf (fid, '%g %g %g %g \n', self.quadMesh(:,i)');
            end
            
            % mark the mesh as not processed since we've just rewriten the
            % mesh program input files
            self.meshProcessed = false;
            
        end
        
        function processMeshDraftAndCoG (self, draft, cog)
            % process a mesh according to draft and CoG options
            %
            %
            
            if ~isempty (draft)
                self.checkNumericScalar (draft, true, 'Draft');
                assert (draft >= 0, ...
                    'Draft must be greater than or equal to zero (it is magnitude of vertical displacement from mean water level).');
            end
            
            if isempty (cog)
                cog = [0; 0; 0];
            else
                assert ( isnumeric (cog) ...
                         && isvector (cog) ...
                         && isreal (cog) ...
                         && numel (cog) == 3 ...
                         , 'CentreOfGravity must be a 3 element real-valued vector' );
                     
                cog = cog(:);
            end
            
            if isempty (draft)
                % leave mesh and CoG as they are
                zdisp = 0;
            else
                % calcualte the shift required to get the desired draft.
                % The draft is the distance from the lowest point on the
                % mesh to the mean water level
                meshminz = min (self.meshVertices(3,:));
            
                zdisp = -meshminz - draft;
            end
            
            self.meshVertices(3,:) = self.meshVertices(3,:) + zdisp;
            
            self.centreOfGravity = cog;
            self.centreOfGravity(3) = self.centreOfGravity(3) + zdisp;
            
        end
        
        function clearMeshAndForceData (self)
            
            % mesh data
            self.axiMeshR = [];
            self.axiMeshZ = [];
            self.meshVertices = [];
            self.quadMesh = [];
            self.triMesh = [];
            self.nMeshNodes = [];
            self.nQuads = [];
            self.meshTranslation = [0; 0; 0];
            
            % mesh results
            self.hydrostaticForces = [];
            self.hydrostaticForcePoints = [];
            self.centreOfBuoyancy = [];
            self.WPA = [];
            self.mass = [];
            self.inertia = [];
            self.kH = [];
            
            self.defaultTargetPanels = 250;
            
            self.meshProcessed = false;
            self.meshPlottable = false;
            self.meshType = 'none';
            self.stlLoaded = false;
            
        end
        
        function [hmesh, hax, hfig] = polyMeshPlot (self, v, f, varargin)
            % plot a polygonal mesh
            %   QUADMESH(QUAD,X,Y,Z,C) displays the quadrilaterals defined in the M-by-4
            %   face matrix QUAD as a mesh.  A row of QUAD contains indexes into
            %   the X,Y, and Z vertex vectors to define a single quadrilateral face.
            %   The edge color is defined by the vector C.
            %
            %   QUADMESH(QUAD,X,Y,Z) uses C = Z, so color is proportional to surface
            %   height.
            %
            %   QUADMESH(TRI,X,Y) displays the quadrilaterals in a 2-d plot.
            %
            %   H = QUADMESH(...) returns a handle to the displayed quadrilaterals.
            %
            %   QUADMESH(...,'param','value','param','value'...) allows additional
            %   patch param/value pairs to be used when creating the patch object. 
            %
            %   See also patch
            %
            
            options.Axes = [];
            options.PatchParameters = {};
            
            options = parse_pv_pairs (options, varargin);
            
            if check.isAxesHandle (options.Axes, false, 'options.Axes')
                assert (numel (options.Axes) == 1, 'Axes must be a scalar');
                hax = options.Axes;
                hfig = get (hax, 'Parent');
            elseif isempty (options.Axes)
                hfig = figure;
                hax = axes;
            else
                error ('Axes must be an axes object, or empty.')
            end

            hmesh = patch( 'faces', f, ...
                           'vertices', v, ...
                           ... 'facevertexcdata', c(:),...
                           'facecolor', 'none', ...
                           'facelighting', 'none', ...
                           'edgelighting', 'flat',...
                           'parent', hax, ...
                           options.PatchParameters{:} );
            
        end
        
        function calcMeshProps (self)
            % calculates some basic properties of the mesh
            
            meshminx = min (self.meshVertices(1,:));
            meshmaxx = max (self.meshVertices(1,:));
            meshminy = min (self.meshVertices(2,:));
            meshmaxy = max (self.meshVertices(2,:));
            meshminz = min (self.meshVertices(3,:));
            meshmaxz = max (self.meshVertices(3,:));
            
            self.meshBoundBox = [ meshminx, meshmaxx; 
                                  meshminy, meshmaxy;
                                  meshminz, meshmaxz ];
            
            self.meshSize = self.meshBoundBox(:,2) - self.meshBoundBox(:,1);

        end
        
        function addCircleSurfMesh (self, r, z1, z2, ner, axi, revquads, f)
            
            % ner - Elements in radius
            % r - Outer radius of disc
            % f - Fraction (with respect to outer radius) where central square appears
            % z1 - z position of 0,0
            % z2 - z position on rim

            if nargin < 6
                axi = true;
            end
            
            if nargin < 7
                revquads = false;
            end
            
            if nargin < 8
                f = 0.8;
            end
            
            % Create the 2D mesh
            [Fc, Vc, ~, indEdge] = discQuadMesh (ner, r, f);
            
            if axi
                
                indl0 = find (Vc(:,2) < -10*eps);
%                 indge0 = find (Vc(:,1) >= 0);
                
                rmind = [];
                for ind = 1:size(Fc,1)
                    if any ( any (Fc(ind,:) == indl0) )
                        rmind = [rmind, ind];
                    end
                end
                
                Fc(rmind,:) = [];
                
                [Fc, Vc] = removeNotIndexed (Fc, Vc);
                
            end
            
            [~, rho] = cart2pol (Vc(:,1), Vc(:,2));
            
            rho(rho>r) = r;
            
            Vc(:,3) = interp1 ([0, r], [z1, z2],  rho );
            
            Fc = Fc + size (self.meshVertices, 2);
            
            if revquads
                Fc = fliplr (Fc);
            end
            
            self.quadMesh = [self.quadMesh, Fc.'];
            
            self.meshVertices = [ self.meshVertices, Vc.'];
            
            [Fc,Vc,ind1,ind2] = mergeVertices (self.quadMesh.', self.meshVertices.', 10);
            
            self.quadMesh = Fc.';
            self.meshVertices = Vc.';
            
            self.nMeshNodes = size (self.meshVertices, 2);
            self.nQuads = size (self.quadMesh, 2);
            
        end
        
    end
    
end