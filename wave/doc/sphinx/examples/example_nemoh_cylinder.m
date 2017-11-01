% example_nemoh_cylinder.m
%
% Example file for nemoh package generating a basic cylinder
%
%

dir = fileparts ( which ('example_nemoh_cylinder') );

inputdir = fullfile (dir, 'example_nemoh_cylinder_output');

%% create the Nemoh body

% create a body object which will be the cylinder
cylinder = nemoh.body (inputdir);

radius = 5; % Radius of the cylinder
draft = -10; % Height of the submerged part
r = [radius  radius  0]; 
z = [0       draft   draft];
ntheta = 30;
verticalCentreOfGravity = -2;

% The body shape is defined using a 2D profile rotated around the z axis,
% created using the makeAxiSymmetricMesh method. The nemoh.body object
% actually has a makeCylinderMesh method which we could use to create such
% a mesh, but the makeAxiSymmetricMesh method is used here just for
% demonstration of the capability. There is also a makeSphereMesh method,
% other basic shapes may be introduced in the future. Existing NEMOH meshes
% can be imported, and also STL files.
cylinder.makeAxiSymmetricMesh (r, z, ntheta, verticalCentreOfGravity);

%% draw the course body mesh (will be refined later)

cylinder.drawMesh ();
axis equal;

%% Create the nemoh simulation

% here we insert the cylinder body at creation of the simulation, but could
% also have done this later by calling addBody
sim = nemoh.simulation ( inputdir, ...
                         'Bodies', cylinder );

%% write mesh files

% write mesh file for all bodies (just one in this case)
sim.writeMesherInputFiles ();

%% process mesh files

% process mesh files for all bodies to make ready for Nemoh
sim.processMeshes ();

%% Draw all meshes in one figure

sim.drawMesh ();
axis equal;

%% Generate the Nemoh input file

% generate the file for 10 frequencies in the range defined by waves with
% periods from 10s to 3s.
T = [10, 3];

sim.writeNemoh ( 'NWaveFreqs', 10, ...
                 'MinMaxWaveFreqs', 2 * pi() *  (1./T) );

% The above code demonstrates the use of optional arguments to writeNemoh
% to set the desired wave frequencies. If the wave frequencies were not
% specified a default value would be used. These are not the only possible
% options for writeNemoh. The following optional arguments are available,
% and the defaults used if they are not supplied are also shown:
%
% DoIRFCalculation = true;
% IRFTimeStep = 0.1;
% IRFDuration = 10;
% NWaveFreqs = 1;
% MinMaxWaveFreqs = [0.8, 0.8];
% NDirectionAngles = 1;
% MinMaxDirectionAngles = [0, 0];
% FreeSurfacePoints = [0, 50];
% DomainSize = [400, 400];
% WaterDepth = 0;
% WaveMeasurementPoint = [0, 0];
%
% For more information on these arguments, see the help for the writeNemoh
% method.

%% Run Nemoh on the input files

% The run Method invokes the Nemo programs on the generated input files.
% Before running it also first generates the ID.dat file and input.txt file
% for the problem. See the Nemoh documentation for more information about
% these files. After generating the files, the preprocessor, solver and
% postprocessor are all run on the input files in sequence.
%
sim.run ()

% Other options supported by the run Method, but not used above are:
%
% 'Solver' - integer or string. Used to select the solver for
%   the problem, the following values are possible:
%
%   0 or 'direct gauss' or 'directgauss'
%   1 or 'GMRES'
%   2 or 'GMRES-FHM' or 'GMRES with FHM'
%
%   The string forms are case-insensitive (e.g. 'gmres' works
%   just as well as 'GMRES'.
%
% 'SavePotential' - logical (true/false) flag indicating whther
%   the potential should be saved for visualisation.
%
% 'GMRESRestart' - scalar integer. Restart criteria for the
%   gmres solver types. Ignored for other solvers. Default is
%   20.
%
% 'GMRESTol' - scalar value. Tolerance for the gmres solver
%   types. Ignored for other solvers. Default is 5e-7.
%
% 'GMRESMaxIterations' - scalar integer. Maximum number of
%   iterations allowed for the gmres solver types. Ignored for
%   other solvers. Default is 100.
%
% 'Verbose' - logical (true/false) flag determning whether to
%   display some text on the command line informing on the
%   progress of the simulation.


