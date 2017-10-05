.. EMST documentation master file, created by
   sphinx-quickstart on Fri May  5 14:45:20 2017.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

.. highlight:: matlab

EWST (Edinburgh Wave Simulation Toolbox)
****************************************

The EWST (Edinburgh Wave Simulation Toolbox) is a suite of tools for the
simulation of wave energy devices. EWST has the ability to model devices that
are comprised of rigid bodies, power-take-off systems, and mooring systems. 
Simulations are performed in the time-domain by solving the governing WEC 
equations of motion in 6 degrees-of-freedom.

EWST is derived from `WEC-Sim <http://wec-sim.github.io/WEC-Sim/index.html>`_, 
an open-source wave energy converter simulation tool developed in Matlab/Simulink
using the multi-body dynamics solver Simscape Multibody. The EWST is also 
developed in Matlab, but drops the requirement for Simulink or Simscape 
Multibody. It also aims to be compatible with `Octave <https://www.gnu.org/software/octave/>`_, 
an alternative system able to process much of the standard Matlab code base.
The hydrodynamic data format for both is identical, so hydrodynamic data can
be easily ported between systems. 

EWST replaces the mutlibody modelling parts of the code with the `MBDyn <https://www.mbdyn.org/>`_. 
An advanced Matlab code based mbdyn preprcessor is available to ease the creation
of MBDyn model nput files in Matlab. Detailed documentation of thie preprocesing 
tool may be found in it's own dedicated document.

Purpose
=======

With the existance of Wec-Sim the need for EWST may nt be obvious. EWST addresses 
several main perceived issues with Wec-Sim.

1. *Maintainability:* Wec-Sim being heavily based in Simulink does not lend itself
to maintenance using standard software version control systems (e.g. `Git <https://git-scm.com/>`_, 
`Mercurial <https://www.mercurial-scm.org/>`_). Simulink files cannot be easily compared 
for changes using these systems. 

2. *Debugability:* Debugging a purely code based system is easier than one based 
in Simulink, as the ability to step through the code and navigate the different levels 
of the system is more advanced.
purely code-based 

3. *Interface design:* The developers of EWST have a different interface design 
philosophy which is more conventional than the WEC-Sim method. The EWST interface
is more oriented toward automation and batch processing than the original WEC-Sim
interface. This is mainly to facilitate randomised simulation and optimisation
algorithms.

4. *Modifiability:* Being purely code based, and with all code in one location
(rather than spread throughout simulink models) 

5. *Cost:* WEC-Sim requires many commercial platforms to be operated, EWST can be run 
entirely on free software (although the performance on Matlab will be 
superior).

The EWST developers recognise that not everyone will agree with the points above
or that they justify the creation of a separate system, but it was these needs which
drove it's creation.

An aim of the project will continue to be to maintain compatibility as much as 
possible between the two systems

Developers and Contributers
===========================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   self
   installation
   getting_started



Indices and tables
******************

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`