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

* Qt, version 5.15.2

* [Git](http://git-scm.com/downloads)

Note: use short source and build directory names to avoid the [maximum path length limitation](http://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx#maxpath).

Build
-----
Note: The build process will take approximately 3 hours.

Slicer sources will be checked out automatically according to the git repo and tag indicated on CMakeLists

**CMake GUI and Visual Studio (Recommended)**

1. Start [CMake GUI](https://cmake.org/runningcmake/), select source directory as this repo folder and set build directory to `C:\GeoSlicerBuild`.
2. Add an entry `Qt5_DIR` pointing to `C:/Qt/${QT_VERSION}/${COMPILER}/lib/cmake/Qt5`.
3. Select MP flag for multi processing compilations
4. Keep only Release on `CMAKE_CONFIGURATION_TYPES`
5. Generate the project.
6. Open `C:\GeoSlicerBuild\GeoSlicer.sln`, select `Release` and build the project `ALL_BUILD`.

CMake has a problem with findopenssl.
add 

	set(OPENSSL_INCLUDE_DIR "C:/GeoSlicerBuild/OpenSSL-install/Release/include" )

to line 585 of
C:\Program Files\CMake\share\cmake-3.21\Modules\FindOpenSSL.cmake


If you get error LNK1181: cannot open input file 'optimized.lib' 
https://github.com/Slicer/Slicer/issues/4898

TL;DR;
Cmake is finding a debug python build outside the slicer build folder.
temporarily move away C:/Python36-x64/libs folder to somewhere to make sure it cannot be found during the build
check SimpleITK-build/CmakeCache.txt and VTK-build/CmakeCache.txt for empty or not found PYTHON_DEBUG_LIBRARY:FILEPATH
	

Package
-------

Install [NSIS 2](http://sourceforge.net/projects/nsis/files/)

**CMake and Visual Studio**

1. On `C:\GeoSlicerBuild\Slicer-build` directory, open `Slicer.sln` and build the `PACKAGE` target under `CMakePredefinedTargets`
