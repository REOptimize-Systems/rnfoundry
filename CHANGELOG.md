# CHANGELOG

All notable changes to this project will be documented in this file.
This project adheres to [Keep a Changelog](http://keepachangelog.com/).

## Unreleased
---

### New

### Changes
* MBDYN: allow 'Name' option for more elements, e.g. structuralForce
* EWST: add structural external force automatically if not present

### Fixes
* MBDYN: don't use 'stable' option for setdiff for Octave compatibility
* EWST: work around Octave bug #56172 in wsim.hydroSystem 
* correct CHANGELOG.md

### Breaks


## [2.1.0] - 2020-02-26
---

### New
* MBDyn: added cuboidalbody convenience class
* MBDyn: added pipeBody convenience class

### Changes
* MBDyn: added ability to plot node labels in preprocessor visualisation
* MBDYN: added problem assembly related options UseInAssembly and AssemblyTolerance
* MBDYN: added get*ByLabel methods for mbdyn.pre.system
* MBDYN: report component names in output of mbdyn.postproc.displayNetCDFVarNames
* MBDYN: add support for plugin variables
* MBDYN: Allow non-inline scalar function declaration
* Now return index of matching string in checkAllowedStrings functions
* EWST: allow empty PTOs to be ignored by wsim.wecSim


### Fixes
* EWST: +wsim/linearPowerTakeOff.m: correct input args in help text

### Breaks


## [2.0.1] - 2020-01-22
---

### New
* Added this change log to track changes across versions
* MBDyn: added many components to MBDyn interface
* MBDyn: added support for stream file driver to communicate arbitrary data to MBDyn during simulation. 
* MBDyn: aded support for stream output to communicate MBDyn simulation data to an external software.
* MBDyn: added netcdf support on MS Windows
* MBDyn: added support for GiNaC element on MS Windows
* EWST: added 'iterate' option for added mass calculation for improved stability
* EWST: added many features to help debug models, e.g. wave type which is actually just a sinusoidal force
* EWST: added many features to Nemoh interface, exposing more underlying Nemoh options
* Added tools to assist with creating quad meshes (mainly for Nemoh)

### Changes

### Fixes
* EWST: fixed bug which meant gravity element could not be used and gravity needed to be added manually for non-hydro bodies
* Fixed windows build system, particularly missing symbols linker problem due to Mingw compiler bug
* Various Octave incompatibilites, added workarounds for various Octave bugs

### Breaks
* EWST simulations which worked around the gravity bug described above, will require modification

