%% example_radial_flux_pm_with_ratio_specification.m
%
% This script sets up an example simulation of a radial flux permanent
% magnet machine using the RenewNet Foundry permanent magnet machine
% toolbox, using dimensionless ratios to set up the design specification.
% The machine simulated is the same as that specified in the other example
% file:
%
% example_radial_flux_permanent_magnet_machine_sim.m
%
% So you may want to have a look at this example before looking at this
% one.
%
% A machine design is always defined using fields of a structure which we
% usually named 'design'. Throughout the toolbox this is the name used.
% Here, instead of specifying the machine dimensions using the actual
% physical values, we instead specify them using one dimension and a number
% of dimensionless ratios. 
%
% This alternative method can be useful for a number of reasons, such as in
% optimisation, or for when tweaking designs manually, without creating
% impossible designs.
%
% Again, the machine we will simulate is a 3-phase, twelve-pole machine
% with an overlapping winding. The machine design is arbitrary and probably
% not a particularly good example of a machine design, and is purely for
% demonstrating the tools.
% 
%% Setting up the design
%
% So first we set up some design variables describing the machine in the
% structure. The first thing we do is set up the winding arrangement. The
% way this is specified is based on the Stator slot/coil/winding
% terminology presented in:
%
% J. J. Germishuizen and M. J. Kamper, "Classification of symmetrical
% non-overlapping three-phase windings," in The XIX International
% Conference on Electrical Machines - ICEM 2010, 2010, pp. 1-6.
%
% To summarise this the followng variables describe a winding, we don't
% need to specify all of these though, some are calculated:
%
% Poles - total number of magnetic Poles in the machine (the number of
%         magnets in permanent magnet machine)
% Phases - the number of electrical Phases in a machine
% Qs  -  total number of stator slots in all Phases combined
% Qc  -  total number of winding coils in all Phases combined
% yp - Average coil pitch as defined by (Qs/Poles)
% yd - Actual coil pitch as defined by round(yp) +/- k
% q  -  number of slots per pole and phase
% qn  -  numerator of q
% qd  -  denominator of q
% qc - number of coils per pole and phase, i.e. the ratio coils / (Poles * Phases)
% qcn  -  numerator of qc
% qcd  -  denominator of qc
%
% In addition, coils can either be single layered (only one coil side per
% slot, not overlapping in the slots), or double layered (two coils sit on
% top of each other in a slot). In each case the following relationships
% hold:
%
% Single layer
%   q = 2qc
%   Qs = 2Qc
% Double layer
%   q = qc
%   Qs = Qc
%
% With this new knowledge we can set up the winding design we will use for
% our example machine.

% Before we start, we'll get rid of anything in the workspace that might
% confuse us, i.e. any existing design and simoptions structure
clear design simoptions

% we will design a 12-pole machine, so it will have 12 magnets, and 6
% pole-pairs
design.Poles = 12;
% Choose the number of Phases, the conventional 3
design.Phases = 3;
% The desired number of layers is stored in 'CoilLayers'
design.CoilLayers = 2;
% The type of winding is specified as a string, it can be 'overlapping' or
% 'nonoverlapping'
% design.WindingType = 'overlapping';
% Next we can specify the winding by stating the ratio of coils to Poles
% and slots. This value must be a fraction object, which is created as
% below. To simplify things we will use one coil per pole and phase, but
% many other ratios are possible, see the help for "fr" (run "help fr" at
% the command prompt) for more information on using fractions objects
design.Qc = design.Phases * design.Poles;
design.qc = fr(design.Qc,design.Poles*design.Phases);
% Specify the actual coil slot pitch in slots
design.yd = 4;
% We must also specify a fill factor for the coils, this is the wire fill
% factor acheived
design.CoilFillFactor = 0.6;
% We must also specify either the number of turns, of the diameter of the
% wire used in the coils. If we specify the turns, the wire diameter is
% calculated, and vice-versa. The wire diameter is specified in the field
% "Dc" and the number of turns in the field "CoilTurns". In this case we
% will specify the number of turns
design.CoilTurns = 500;
% The number of series coils, or parallel branches of coils in a phase is
% controlled with the fields 'CoilsPerBranch' or 'Branches'. We must set
% one or both of these fields. Here we will use all coils in series by
% setting the number of branches to one. 
design.Branches = 1;

% Now set up actual dimensions of the machine components. There are
% actually three different ways to do this. One is to specify the outer
% radius of the machine, and then the radial lengths of various components
% and other dimensions. This is the method we use here. Another way is to
% specify the radial distance from the centre of the machine of the
% components, or alternatively specify the outer radius, then all the other
% dimensions through a set of dimensionless ratios based on this first
% dimension. There are various reasons this can be more convenient.
%
% However, as stated, here we use the lengths and the outer rotor radius.
% What these dimensions are will be more obvious when we open the design
% for plotting/viewing later.

      
% The outer radius of the rotor back iron
design.Rbo = 0.5;
% The height of the magnets in the radial direction
design.RmoVRbo = 0.98;
% The thickness of the rotor back iron
design.RmiVRmo = 0.9898;
% The thickness of the stator yoke (the part which the slots sit on)
design.RaoVRmi = 0.9938;
% The radial height of a slot opening
design.RtsbVRao = 0.9793;
% The height of the slot shoe at the point it joins the slot wall
design.RyoVRtsb = 0.9364;
% The height of the slot shoe at the point it joins the slot wall
design.RyiVRyo = 0.9661;
% The radial air gap length between rotor and stator
design.tsgVtsb = 0.3;
% magnet pitch in radians
design.thetamVthetap = 0.8;
% coil slot opening pitch in radians ( space a coil has to fit in a slot )
% at the slot end closest to the air gap
design.thetacgVthetas = 0.7;
% coil slot opening pitch in radians ( space a coil has to fit in a slot )
% at the slot end closest to the armeture yoke
design.thetacyVthetas = 0.8;
% the pitch in radians of gap between the shoes that partially cover the
% slot openings
design.thetasgVthetacg = 0.8;
% stack length of the machine, the depth along the cylindrical axis of the
% machine
design.lsVtm = 120.0;

% next we tell the simulation what type of stator/rotor arrangement we
% have. There are two options at the moment, either a stator on the inside
% "facing" outwards, i.e. with the slots pointing outwards and with a rotor
% on the outside, or we can have the opposite arrangement with an internal
% rotor and internally facing stator. 
design.ArmatureType = 'internal';

% We must also specify some materials in the machine, these can either be
% names of materials already existing in the materials library, or
% materials structures in the same format as those in the materials library
design.MagFEASimMaterials.AirGap = 'Air';
design.MagFEASimMaterials.Magnet = 'NdFeB 32 MGOe';
design.MagFEASimMaterials.FieldBackIron = '1117 Steel';
design.MagFEASimMaterials.ArmatureYoke = design.MagFEASimMaterials.FieldBackIron;
design.MagFEASimMaterials.ArmatureCoil = '36 AWG';

% for convenience, a function is provided to complete a lot of design
% parameters of the machine from the variables provided above. This
% function is completedesign_RADIAL_SLOTTED. It requires you to supply both
% a design structure and a simoptions structure. We won't worry about
% simoptions for now, this can be empty for the moment. MOre on simoptions
% later.

% create the empty simoptions structure
simoptions = struct();
% complete the design
design = completedesign_RADIAL_SLOTTED(design, simoptions);

% We can take a look at the completed design, and all the variables
% describing the machine which have been added to the design structure
design

%% Simulating the Machine
%
% The first stage in simulating the machine is to gather electromagnetic
% data using FEMM, or mfemm. The function simfun_RADIAL_SLOTTED does this
% for this type of machine. For other machine types the function name
% follows the same pattern. These functions are found in the odesim
% directory for each machine. 
%
%
% At this point we reintroduce the simoptions structure mentioned earlier.
% This structure is intended to specify various simulation options.

% GetVariableGapForce is a flag which determines whether
% simfun_RADIAL_SLOTTED does a series of force simulations at progressively
% smaller air gaps to create data on how the force varies with respect to
% this. We set this to false to save time.
simoptions.GetVariableGapForce = false;

% now run simfun_RADIAL_SLOTTED, this function performs various simulations
% of the machine
[design, simoptions] = simfun_RADIAL_SLOTTED(design, simoptions);

% At this point we now have various pieces of information added to the
% design structure taken from FEA simulations. These must be now be
% post-processed before they are any use however. The kind of information
% added is sampling of the integral of the vector potential and flux
% density in the slots at multiple positions.

figure;
[AX,H1,H2] = plotyy( design.intAdata.slotPos, design.intAdata.slotIntA(:,1), ... 
                     design.intBdata.slotPos, design.intBdata.slotIntB(:,1) );
set(H1,'LineStyle','none');
set(H2,'LineStyle','none');
set(H1,'Marker','x');
set(H2,'Marker','x');
set(H1,'Color','r')
set(H2,'Color','b')
xlabel('Slot Position', 'fontsize', 14);
set(get(AX(1),'Ylabel'),'String','Vector Potential Integral') 
set(get(AX(2),'Ylabel'),'String','Flux Density Integral') 
set(get(AX(1),'Ylabel'), 'fontsize', 14);
set(get(AX(2),'Ylabel'), 'fontsize', 14);

% By convention the postprocessing functions begin with "finfun_" and the
% postprocessing function for the slotted radial flux machine is named
% finfun_RADIAL_SLOTTED. It has the same calling syntax as
% simfun_RADIAL_SLOTTED
%
% Before calling finfun_ however, we need to add some more information to
% the simoptions structure. This information includes things such as the
% density of materials and is provided in the 'evaloptions' field of the
% simoptions stucture, which itself is also a structure. To save time, we
% will use a function which provides some common defaults for this:

simoptions.Evaluation = designandevaloptions_RADIAL_SLOTTED();

% we could have added these at any time, and and you would normally want to
% add them at the very start of a simulation.
% designandevaloptions_RADIAL_SLOTTED can also take in an existing
% evaloptions structure and fill in the missing values with defaults,
% keeping your choices

% The post processing functions also set up certain parameters for later
% dynamic machine simulation. One of the parameters it sets up is a load
% resistance, stored in design.LoadResistance. We can either supply this
% value directly, or alternatively it can be convenient to supply a
% unitless ratio of the phase resistance and the load resistance value,
% from which design.LoadResistance is calculated once the phase resistance
% is known. Here we'll use this method, setting the load resistance to be
% 10 times whatever the phase resistance is.
design.RlVRp = 10;

% The winding arrangement can now also be specified, here we use all series
% connected coils
design.Branches = 1;

% Now we are ready to post-process
[design, simoptions] = finfun_RADIAL_SLOTTED(design, simoptions);

% After post-processing there is a lot more useful information added to the
% design structure. One of the most importent things added is a piecewise
% polynomial fit to the flux linkage waveform in the machine. This fit is
% based on a technique called Shape Language Modelling in which smoothly
% joined splines are fitted to a function, joined at multiple 'knot'
% points. For more information on slm objects, see slmengine.m and the
% tutorial examples in slm_tutorial. The flux linkage slm is saved in the
% field slm_fluxlinkage. We can plot this, with the knot points shown using
% green dashed lines using plotslm

plotslm( design.slm_fluxlinkage, {'dy'})

% Note that the fit is performed over two poles and normalised to the
% number of poles, rather than being the actual displacement. This is
% convenient for reasons we won't go into here.

% The slm objects are useful as they are guaranteed to have a smooth first
% derivative, and can be made to fit a periodic waveform. This makes
% evaluating the derivative w.r.t. displacement at any position very easy.
% To evaluate a periodic slm at any position we must use periodicslmeval

x = linspace(-2, 4, 1000);
y = periodicslmeval(x,design.slm_fluxlinkage,1);
figure;
plot( x, y );
ylabel('Flux Linkage Derivative', 'FontSize', 14);
xlabel('Position', 'FontSize', 14);
clear x y

% Other useful information includes the coil and phases resistances and
% inductances
design.CoilResistance
design.PhaseResistance
design.CoilInductance
design.PhaseInductance

% There are also masses of various components, the rotor moment of inertia,
% an estimate of the harmonic distortion in the voltage waveform, and
% several other useful things. Much of the extra information is intended
% for use by the dynamic simulation functions the toolbox provides, and
% isn't much use otherwise.

% The finite element analysis performed is based on the mfemm toolbox. This
% toolbox stores problems in structure, and the last problem is left in the
% design stucture, so we can have a look at the geometry by plotting it
plotfemmproblem(design.FemmProblem);

