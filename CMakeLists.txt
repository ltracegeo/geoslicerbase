cmake_minimum_required(VERSION 3.13.4)

set(ADDITIONAL_CXX_FLAGS /MP)
set(ADDITIONAL_C_FLAGS /MP)
set(CMAKE_CONFIGURATION_TYPES Release)

if(NOT DEFINED Qt5_DIR)
  set(Qt5_DIR "C:/Qt/5.15.2/msvc2019_64/lib/cmake/Qt5")
endif()

# Enable C++11
if(NOT DEFINED CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 11)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Slicer sources
include(FetchContent)
if(NOT DEFINED slicersources_SOURCE_DIR)
  # Download Slicer sources and set variables slicersources_SOURCE_DIR and slicersources_BINARY_DIR
  FetchContent_Populate(slicersources
    GIT_REPOSITORY git@bitbucket.org:ltrace/slicer.git
    GIT_TAG e2d2d5b79523b6832d64049ce73529b38e976abf
    GIT_PROGRESS   1
    )
else()
  set(slicersources_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/slicersources-subbuild)
endif()

# macOS initialization
set(CMAKE_MODULE_PATH ${slicersources_SOURCE_DIR}/CMake ${CMAKE_MODULE_PATH})
include(SlicerInitializeOSXVariables)

project(GeoSlicer)

# Configure Application
set(Slicer_APPLICATIONS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Applications)
set(Slicer_MAIN_PROJECT "GeoSlicerApp")

# Set organization
set(Slicer_ORGANIZATION_DOMAIN "ltrace.com.br")
set(Slicer_ORGANIZATION_NAME   "LTrace")

# Default home and favorite modules
#set(Slicer_DEFAULT_HOME_MODULE "Home")
#set(Slicer_DEFAULT_FAVORITE_MODULES "Data, Volumes, Models, Transforms, Markups, SegmentEditor")

# Configure SuperBuild
set(SUPERBUILD_TOPLEVEL_PROJECT Slicer)
set(EXTERNAL_PROJECT_ADDITIONAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/SuperBuild")
include(ExternalProjectDependency)

# Additional Slicer dependencies looked up in EXTERNAL_PROJECT_ADDITIONAL_DIR
set(Slicer_ADDITIONAL_DEPENDENCIES
  )

#  Enable listed remote modules from ITK 
set(Slicer_ITK_ADDITIONAL_MODULES
  )

if(NOT CMAKE_CONFIGURATION_TYPES)
  set(Slicer_DEFAULT_BUILD_TYPE "Release")
endif()
include(SlicerInitializeBuildType)
include(SlicerInitializeReleaseType)

# Set application bundle identifier for macOS
if(APPLE)
  set(Slicer_MACOSX_BUNDLE_GUI_IDENTIFIER "br.com.ltrace.geoslicer")
endif()

# Installation folder and admin account requirement for Windows
if(WIN32)
  # Note: To avoid escaping issue, make sure to use forward slash when setting
  #       "Slicer_CPACK_NSIS_INSTALL_ROOT". It is replaced by "\\\\" in SlicerCPack.
  set(Slicer_CPACK_NSIS_INSTALL_REQUIRES_ADMIN_ACCOUNT OFF)
  if(Slicer_CPACK_NSIS_INSTALL_REQUIRES_ADMIN_ACCOUNT)
    # User has administrative privileges, therefore we can install to shared folder
    # "C:\Program Files" or "C:\Program Files (x86)".
    if(CMAKE_CL_64)
      set(Slicer_CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES64")
    else()
      set(Slicer_CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES")
    endif()
  else()
    # We do not require administrative privileges, therefore we install to user folder
    # "C:\Users\<username>\AppData\Local".
    set(Slicer_CPACK_NSIS_INSTALL_ROOT "$LOCALAPPDATA/${Slicer_ORGANIZATION_NAME}")
  endif()
endif()

if(WIN32)
  option(Slicer_BUILD_WIN32_CONSOLE             "Build application executable as a console app"       OFF)
endif()

option(Slicer_BUILD_DICOM_SUPPORT               "Build application with DICOM support"                ON)
option(Slicer_BUILD_DIFFUSION_SUPPORT           "Build application with Diffusion support"            ON)
option(Slicer_BUILD_EXTENSIONMANAGER_SUPPORT    "Build application with ExtensionManager support"     ON)
option(Slicer_BUILD_MULTIVOLUME_SUPPORT         "Build application with MultiVolume support"          ON)
option(Slicer_BUILD_PARAMETERSERIALIZER_SUPPORT "Build application with parameter serializer support" ON)
option(Slicer_USE_PYTHONQT                      "Build application with Python support"               ON)
option(Slicer_USE_SimpleITK                     "Build application with SimpleITK support"            ON)

option(Slicer_BUILD_BRAINSTOOLS                 "Build application with BRAINSTools module"           ON)
option(Slicer_BUILD_DataStore                   "Build application with DataStore module"             ON)
option(Slicer_BUILD_CompareVolumes              "Build application with ChangeTrackerPy module"       ON)
option(Slicer_BUILD_LandmarkRegistration        "Build application with LandmarkRegistration module"  ON)
option(Slicer_BUILD_SurfaceToolbox              "Build application with SurfaceToolbox module"        ON)
option(Slicer_BUILD_WEBENGINE_SUPPORT           "Build application with webengine support"            ON)

# Enable Slicer built-in modules
# set(Slicer_CLIMODULES_ENABLED
  # ResampleDTIVolume             # Needed by ResampleScalarVectorDWIVolume
  # ResampleScalarVectorDWIVolume # Depends on DiffusionApplications, needed by CropVolume
  # )
# set(Slicer_QTLOADABLEMODULES_ENABLED
  # )
# set(Slicer_QTSCRIPTEDMODULES_ENABLED
  # )

# Disable Slicer built-in modules
# set(Slicer_CLIMODULES_DISABLED
  # )
# set(Slicer_QTLOADABLEMODULES_DISABLED
  # )
# set(Slicer_QTSCRIPTEDMODULES_DISABLED
  # )

# Enable/Disable Slicer custom modules: To create a new module, use the SlicerExtensionWizard.
set(Slicer_EXTENSION_SOURCE_DIRS
  #${GeoSlicer_SOURCE_DIR}/Modules/CLI/MyCLIModule
  #${GeoSlicer_SOURCE_DIR}/Modules/Loadable/MyLoadableModule
  #${GeoSlicer_SOURCE_DIR}/Modules/Scripted/Home
  )

# Add remote extension source directories

# SlicerJupyter
set(extension_name "SlicerJupyter")
set(${extension_name}_SOURCE_DIR "${CMAKE_BINARY_DIR}/${extension_name}")
FetchContent_Populate(${extension_name}
 SOURCE_DIR     ${${extension_name}_SOURCE_DIR}
 GIT_REPOSITORY https://github.com/fbordignon/SlicerJupyter.git
 GIT_TAG        087cb22b64b4171618cc175ace5099771baef3f3
 GIT_PROGRESS   1
 QUIET
 )
list(APPEND Slicer_EXTENSION_SOURCE_DIRS ${${extension_name}_SOURCE_DIR})

# SegmentMesher
set(extension_name "SegmentMesher")
set(${extension_name}_SOURCE_DIR "${CMAKE_BINARY_DIR}/${extension_name}")
FetchContent_Populate(${extension_name}
 SOURCE_DIR     ${${extension_name}_SOURCE_DIR}
 GIT_REPOSITORY https://github.com/fbordignon/SlicerSegmentMesher.git
 GIT_TAG        caa009dd6e4f3a505adce95beadda8fe817485a9
 GIT_PROGRESS   1
 QUIET
 )
list(APPEND Slicer_EXTENSION_SOURCE_DIRS ${${extension_name}_SOURCE_DIR})

# SegmentEditorExtraEffects
set(extension_name "SegmentEditorExtraEffects")
set(${extension_name}_SOURCE_DIR "${CMAKE_BINARY_DIR}/${extension_name}")
FetchContent_Populate(${extension_name}
 SOURCE_DIR     ${${extension_name}_SOURCE_DIR}
 GIT_REPOSITORY https://github.com/lassoan/SlicerSegmentEditorExtraEffects.git
 GIT_TAG        16da8d87c6b7a329f3570bcc4750e8719052213f
 GIT_PROGRESS   1
 QUIET
 )
list(APPEND Slicer_EXTENSION_SOURCE_DIRS ${${extension_name}_SOURCE_DIR})

# RawImageGuess
set(extension_name "RawImageGuess")
set(${extension_name}_SOURCE_DIR "${CMAKE_BINARY_DIR}/${extension_name}")
FetchContent_Populate(${extension_name}
 SOURCE_DIR     ${${extension_name}_SOURCE_DIR}
 GIT_REPOSITORY https://github.com/acetylsalicyl/SlicerRawImageGuess.git
 GIT_TAG        859fca3c667d1b0fe3919f9952f274eeaac60b7c
 GIT_PROGRESS   1
 QUIET
 )
list(APPEND Slicer_EXTENSION_SOURCE_DIRS ${${extension_name}_SOURCE_DIR})

# MarkupsToModel
set(extension_name "MarkupsToModel")
set(${extension_name}_SOURCE_DIR "${CMAKE_BINARY_DIR}/${extension_name}")
FetchContent_Populate(${extension_name}
 SOURCE_DIR     ${${extension_name}_SOURCE_DIR}
 GIT_REPOSITORY https://github.com/SlicerIGT/SlicerMarkupsToModel.git
 GIT_TAG        21e43a8978d5634b8702e8ee798f94957aa7d6f0
 GIT_PROGRESS   1
 QUIET
 )
list(APPEND Slicer_EXTENSION_SOURCE_DIRS ${${extension_name}_SOURCE_DIR})


# Add Slicer sources
add_subdirectory(${slicersources_SOURCE_DIR} ${slicersources_BINARY_DIR})
