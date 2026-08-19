Build and Package GeoSlicer
==============================

This document summarizes how to build and package GeoSlicer on Windows and Linux.
For more details, see [3D Slicer Developer Wiki](https://slicer.readthedocs.io/en/latest/developer_guide/index.html)

## Building with Docker (Recommended)

The easiest way to build GeoSlicer is by using the provided Docker containers. This method ensures a consistent build environment and avoids the need to manually install dependencies.

### Prerequisites

*   [Docker](https://docs.docker.com/get-docker/)
*   [Docker Compose](https://docs.docker.com/compose/install/)

### Build Steps

1.  **Start the Docker Container:**

    Open a terminal in the root of the repository and run the following command to start the Docker container for your platform:

    **For Windows:**

    ```bash
    docker compose -f docker-compose.public.yml up -d geoslicerbase-windows --wait --build
    ```

    **For Linux:**

    ```bash
    docker compose -f docker-compose.public.yml up -d geoslicerbase-linux --wait --build
    ```

2.  **Update CMakeLists.txt:**

    Before building, you need to update the `CMakeLists.txt` file with the correct git remote URL and commit hash. The `update_cmakelists_content.py` script automates this process.

    **For Windows:**

    ```bash
    docker compose exec -T geoslicerbase-windows python c:/geoslicerbase/tools/update_cmakelists_content.py --commit 8c6219abd3f171f938fd5d003cd551db20842c7e --repository https://github.com/ltracegeo/Slicer.git
    ```

    **For Linux:**

    ```bash
    docker compose exec -T geoslicerbase-linux python /geoslicerbase/tools/update_cmakelists_content.py --commit 8c6219abd3f171f938fd5d003cd551db20842c7e --repository https://github.com/ltracegeo/Slicer.git
    ```

3.  **Build and Package GeoSlicer:**

    Once the `CMakeLists.txt` is updated, you can use the `build_and_pack.py` script to build and package GeoSlicer.

    **For Windows:**

    ```bash
    docker compose exec -T geoslicerbase-windows python c:/geoslicerbase/tools/build_and_pack.py --source c:/geoslicerbase --avoid-long-path --jobs 8 --type Release --no-export
    ```

    **For Linux:**

    ```bash
    docker compose exec -T geoslicerbase-linux python /geoslicerbase/tools/build_and_pack.py --source /geoslicerbase --jobs 8 --type Release --no-export
    ```

4.  **Shutdown the Docker Container:**

    After the build is complete, you can stop the Docker container:

    ```bash
    docker compose down
    ```

## Manual Build

If you prefer to build GeoSlicer manually, ensure your system meets the requirements. You can follow the [3D Slicer build instructions](https://slicer.readthedocs.io/en/latest/developer_guide/build_instructions/index.html) to set up your environment for your specific platform.

### Prerequisites

*   **Qt 5.15.2**
*   **CMake 3.16.3+**
*   **Git**
*   **Python 3.12+** (for helper scripts)
*   **Visual Studio 2022** (Windows) or **GCC/Clang** (Linux)

### Build Steps

#### 1. Update CMakeLists.txt

The `CMakeLists.txt` is configured to automatically detect the remote URL of the Slicer repository. However, you often need to specify a particular fork or commit. You can do this manually or using the provided helper script.

**Using the helper script (Recommended):**

```bash
python tools/update_cmakelists_content.py --commit <COMMIT_HASH> --repository <REPOSITORY_URL>
```

**Manual modification:**

Open `CMakeLists.txt` and locate the `FetchContent_Populate(slicersources ...)` section. Update the `GIT_REPOSITORY` and `GIT_TAG` as needed:

```cmake
FetchContent_Populate(slicersources
  GIT_REPOSITORY "https://github.com/ltracegeo/slicer.git"
  GIT_TAG 8c6219abd3f171f938fd5d003cd551db20842c7e
  GIT_PROGRESS 1
)
```

#### 2. Configure and Build

You can use the `build_and_pack.py` script locally if your environment is correctly configured (e.g., `Qt5_DIR` is set or in a standard location).

**Windows:**

```bash
python tools/build_and_pack.py --source . --avoid-long-path --jobs 8 --type Release --no-export
```

**Linux:**

```bash
python tools/build_and_pack.py --source . --jobs 8 --type Release --no-export
```

Alternatively, you can use standard CMake commands,  following the official [3D Slicer build instructions](https://slicer.readthedocs.io/en/latest/developer_guide/build_instructions/index.html) for your operating system:

```bash
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --config Release -j 8
```

## Troubleshooting

This section provides solutions to common issues you might encounter during the build process.

### Build Log

The `build_and_pack.py` script creates a `build.log` file in the `tools` directory. If you encounter any issues during the build process, this log file is the first place to check for detailed error messages.

### Windows: Long Path Limitation

On Windows, you may encounter errors if the installation path for GeoSlicer exceeds the default character limit. To resolve this, you need to enable long path support in the Windows Registry.

For detailed instructions, please refer to the official Microsoft documentation: [Enable Long Paths in Windows](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=registry).


### OpenSSL Linker Error

If you encounter a linker error on Windows such as `LNK1181: cannot open input file 'optimized.lib'`, it typically means CMake could not locate the OpenSSL libraries required for the build. For more context, see this related issue: [Slicer/Slicer#4898](https://github.com/Slicer/Slicer/issues/4898).

The recommended way to fix this is to specify the OpenSSL installation path when you configure the project with CMake. You can do this by setting the `OPENSSL_ROOT_DIR` variable in the `../CMake/share/cmake-<version>/Modules/FindOpenSSL.cmake`.

```
	set(OPENSSL_INCLUDE_DIR "C:/GeoSlicerBuild/OpenSSL-install/Release/include" )
```


### Python conflict

During the build process, CMake might find a different Python installation on your system (e.g., from the system's PATH environment variable) instead of the one required by the Slicer build. This can lead to unexpected build failures.

Temporarily remove other Python directories from your system's `PATH` environment variable to ensure CMake finds the correct Python environment provided with the Slicer build.
