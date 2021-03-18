Build and Package GeoSlicer
==============================

This document summarizes how to build and package GeoSlicer on Windows. Instructions for Linux and macOS are similar.
For more details, see [3D Slicer Developer Wiki](http://wiki.slicer.org/slicerWiki/index.php/Documentation/Nightly/Developers)

Prerequisites 
-------------

* Microsoft Windows 10

* Supported Microsoft Visual Studio versions:
	* Visual Studio 2019

* [CMake](http://cmake.org/cmake/resources/software.html), version 3.12 or above

* Qt, version 5.51.1

* [Git](http://git-scm.com/downloads)

Note: use short source and build directory names to avoid the [maximum path length limitation](http://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx#maxpath).

Build
-----
Note: The build process will take approximately 3 hours.

Slicer sources will be checked out automatically according to the git repo and tag indicated on CMakeLists

<b>Option 1: CMake GUI and Visual Studio (Recommended)</b>

1. Start [CMake GUI](https://cmake.org/runningcmake/), select source directory as this repo folder and set build directory to `C:\GeoSlicerBuild`.
2. Add an entry `Qt5_DIR` pointing to `C:/Qt/${QT_VERSION}/${COMPILER}/lib/cmake/Qt5`.
3. Select MP flag for multi processing compilations
4. Keep only Release on CMAKE_CONFIGURATION_TYPES
5. Generate the project.
6. Open `C:\GeoSlicerBuild\GeoSlicer.sln`, select `Release` and build the project.

Note: if xeus and xeus-python does not build. add the respective includes to the CMakeLists

xeus:
	include_directories("../OpenSSL-install/Release/include")

xeus-python:
	include_directories("../OpenSSL-install/Release/include")
	include_directories("../pybind11/include")
	include_directories("../pybind11_json/include")

Build them individually using the .sln file of xeus-build and xeus-python-build. 

Package
-------

Install [NSIS 2](http://sourceforge.net/projects/nsis/files/)

<b>Option 1: CMake and Visual Studio (Recommended)</b>

1. In the `C:\GeoSlicerBuild\Slicer-build` directory, open `Slicer.sln` and build the `PACKAGE` target
