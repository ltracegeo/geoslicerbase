""" Script to handle GeoSlicer base project generation, building and packaging. Also exports to OCI bundle if desired. 
"""

import argparse
import subprocess
import sys
import logging
import os
import shutil
import oci
import traceback

from pathlib import Path


# Configure logger
log_file_path = Path(__file__).parent / "build.log"
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
formatter = logging.Formatter(
    "%(asctime)s - %(levelname)s - %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
)
stream_handler = logging.StreamHandler()
stream_handler.setFormatter(formatter)
file_handler = logging.FileHandler(filename=log_file_path.as_posix())
file_handler.setFormatter(formatter)
logger.addHandler(stream_handler)
logger.addHandler(file_handler)


def get_working_dir(args):
    if args.avoid_long_path and sys.platform == "win32":
        path = Path(Path.home().drive + "/gsb")
    else:
        path = Path.home() / "gsb"

    return path


def get_project_build_command(args):
    output_directory_path = get_working_dir(args)
    if sys.platform == "win32":
        command = [
            "cmake",
            "-G",
            "Visual Studio 16 2019",
            "-A",
            "x64",
            "-DQt5_DIR:PATH=C:/Qt/5.15.2/msvc2019_64/lib/cmake/Qt5",
            "-S",
            args.source.as_posix(),
            "-B",
            output_directory_path.as_posix(),
        ]
    else:
        command = f"cmake -S {args.source.as_posix()} -B {output_directory_path.as_posix()} -DCMAKE_BUILD_TYPE:STRING={args.type}"

    return command


def build_command(args):
    if sys.platform == "win32":
        output_directory_path = get_working_dir(args)
        command = (
            f"cmake --build {output_directory_path.as_posix()} --config {args.type}"
        )
    else:
        command = f"make -j{args.jobs}"

    return command


def get_package_command(args):
    if sys.platform == "win32":
        command = f"msbuild PACKAGE.vcxproj /p:Configuration={args.type} /m:{args.jobs}"
    else:
        command = f"make package"

    return command


def get_clean_env_for_build() -> dict:
    """Return a copy of the environment variables.
        For Windows, all the Python-related paths are removed due to a known issue regarding CMake.
        For Linux, the environment is not modified.

    Returns:
        dict: the environment variables
    """
    if sys.platform.startswith("linux"):
        return os.environ.copy()

    """Return a copy of the environment variables with all Python-related paths removed."""
    env = os.environ.copy()
    if "PYTHONPATH" in env:
        del env["PYTHONPATH"]

    path_sep = os.pathsep
    if "PATH" in env:
        env["PATH"] = path_sep.join(
            [p for p in env["PATH"].split(path_sep) if "python" not in p.lower()]
        )

    return env


def process(args):
    if args.only_export:
        only_export_process(args)
        return

    output_directory_path = get_working_dir(args)
    if args.no_cache and output_directory_path.exists():
        logger.info("Deleting old build directory remainings")
        shutil.rmtree(output_directory_path, onerror=onerror)

    output_directory_path.mkdir(exist_ok=True)

    subprocess_as_shell = sys.platform == "win32"
    env = get_clean_env_for_build()

    # Run cmake to generate buildable project
    logger.info("Generating buildable project...")
    command_as_list = get_project_build_command(args)
    run_subprocess(command_as_list, shell=subprocess_as_shell, env=env)

    # Build project
    logger.info("Building project...")
    command_as_list = build_command(args).split()
    run_subprocess(
        command_as_list,
        shell=subprocess_as_shell,
        cwd=output_directory_path.as_posix(),
        env=env,
    )

    # Pack the application
    logger.info("Packaging application...")
    slicer_build_file_path = output_directory_path / "Slicer-build"
    if not slicer_build_file_path.exists():
        raise RuntimeError("Slicer-build folder not found in the project directory.")

    command_as_list = get_package_command(args)
    run_subprocess(
        command_as_list,
        shell=subprocess_as_shell,
        cwd=slicer_build_file_path.as_posix(),
        env=env,
    )

    # Export
    export_application(args, slicer_build_file_path)


def find_geoslicer_base_application_directory_path(
    slicer_build_file_path: Path,
) -> Path:
    CPack_directory_path = slicer_build_file_path / "_CPack_Packages"
    geoslicer_base_application_directory_path = None
    geoslicer_dir_tag = "GeoSlicer"

    for root, _, _ in os.walk(CPack_directory_path.as_posix()):
        path = Path(root)
        if geoslicer_dir_tag in path.name and path.is_dir():
            geoslicer_base_application_directory_path = path
            break

    return geoslicer_base_application_directory_path


def check_oci_configuration(config, logger=logging):
    logger.info("Checking OCI credentials...")
    try:
        oci.config.validate_config(config)
    except (ValueError, oci.config.InvalidConfig):
        raise RuntimeError("OCI Configuration file is invalid. Please check it.")

    logger.info("OCI credentials are okay!")


def upload_file_2_bucket(
    input_file_path, bucket_output_directory, namespace, bucket_name
):
    logger.info("Uploading file to OCI bucket...")
    config = oci.config.from_file()
    check_oci_configuration(config)

    output_bucket_file_path = Path(bucket_output_directory) / input_file_path.name
    if not input_file_path.exists():
        raise AttributeError(f"File {input_file_path.as_posix()} doesn't exist.")

    with open(input_file_path.as_posix(), "rb") as file:
        object_storage_client = oci.object_storage.ObjectStorageClient(config)
        object_storage_client.put_object(
            namespace, bucket_name, output_bucket_file_path.as_posix(), file
        )

    logger.info(
        f"Application base compressed file successfully uploaded. Bucket file path: {output_bucket_file_path.as_posix()}"
    )


def export_application(args, slicer_build_file_path: Path):
    geoslicer_base_directory_path = find_geoslicer_base_application_directory_path(
        slicer_build_file_path
    )
    if geoslicer_base_directory_path is None:
        raise RuntimeError(
            f"Couldn't find the GeoSlicer base application directory in {slicer_build_file_path.as_posix()}"
        )

    # Compress application folder
    logger.info("Compressing GeoSlicer base application directory...")
    geoslicer_base_compressed_file_path = (
        _get_target_directory(args) / geoslicer_base_directory_path.name
    )
    archive_format = "zip" if sys.platform == "win32" else "gztar"
    shutil.make_archive(
        geoslicer_base_compressed_file_path,
        archive_format,
        geoslicer_base_directory_path.parent,
        geoslicer_base_directory_path.name,
    )

    archive_extension = "zip" if sys.platform == "win32" else "tar.gz"
    geoslicer_base_compressed_file_path = geoslicer_base_directory_path.parent / (
        geoslicer_base_directory_path.name + f".{archive_extension}"
    )
    logger.info(
        f"GeoSlicer base application compressed successfully! File path: {geoslicer_base_compressed_file_path.as_posix()}..."
    )

    if args.no_export:
        logger.info("Skipping the exporting to bucket step...")
        return

    # Export to bucket
    build_type = str(args.type).lower()
    bucket_output_directory = f"GeoSlicer/base/{build_type}/{sys.platform}"
    bucket_name = "General_ltrace_files"
    namespace = "grrjnyzvhu1t"
    upload_file_2_bucket(
        geoslicer_base_compressed_file_path,
        bucket_output_directory,
        namespace,
        bucket_name,
    )


def run_subprocess(command, assert_exit_code=True, shell=True, cwd=None, env=None):
    """Wrapper for running subprocess and reading its output"""
    if isinstance(command, str):
        command = command.split()

    with subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        bufsize=1,
        universal_newlines=True,
        shell=shell,
        cwd=cwd,
        env=env,
        encoding="utf-8",
        errors="replace",
    ) as proc:
        try:
            for line in proc.stdout:
                print(f"\t{line}", end="")
        except Exception as error:
            logger.warning(f"SUBPROCESS WARNING: {error}\n{traceback.format_exc()}")

    if assert_exit_code and proc.returncode != 0:
        raise subprocess.CalledProcessError(proc.returncode, proc.args)


def onerror(func, path, exc_info):
    """
    Error handler for ``shutil.rmtree``.

    If the error is due to an access error (read only file)
    it attempts to add write permission and then retries.

    If the error is for another reason it re-raises the error.

    Usage : ``shutil.rmtree(path, onerror=onerror)``
    Reference: https://stackoverflow.com/questions/2656322/shutil-rmtree-fails-on-windows-with-access-is-denied
    """
    import stat

    # Is the error an access error?
    if not os.access(path, os.W_OK):
        os.chmod(path, stat.S_IWUSR)
        func(path)
    else:
        raise


def _get_target_directory(args: argparse.Namespace) -> Path:
    build_type = str(args.type).lower()

    if os.environ.get("USING_DOCKER", 0) == 0:
        return get_working_dir() / "build" / build_type

    if sys.platform == "win32":
        return Path(Path.home().drive) / "geoslicerbase" / "build" / build_type

    return Path("/geoslicerbase") / "build" / build_type


def only_export_process(args):
    output_directory_path = get_working_dir(args)
    slicer_build_file_path = output_directory_path / "Slicer-build"
    export_application(args, slicer_build_file_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Apply dynamic changes to CMakeLists.txt"
    )
    parser.add_argument(
        "--source", help="The source code directory path.", default=None
    )
    parser.add_argument(
        "--jobs", help="The jobs quantity for parallel building.", default=1
    )
    parser.add_argument(
        "--type", help="The build type. Default to Release", default="Release"
    )
    parser.add_argument(
        "--no-export",
        action="store_true",
        help="Skip application exporting to bucket step",
        default=False,
    )
    parser.add_argument(
        "--no-cache",
        action="store_true",
        help="Delete old build files before starting process",
        default=False,
    )
    parser.add_argument(
        "--avoid-long-path",
        action="store_true",
        help="Avoid long path issues",
        default=False,
    )
    parser.add_argument(
        "--only-export",
        action="store_true",
        help="Only export the generated package",
        default=False,
    )

    args = parser.parse_args()

    if args.source is None:
        raise AttributeError(
            "The source code directory path is missing! Aborting process..."
        )

    args.source = Path(args.source).absolute()

    try:
        logger.info(f"Starting build & package process...")
        process(args)
    except Exception as error:
        logger.info(f"Found a problem! Cancelling process...")
        logger.info(f"Error: {error}\n{traceback.format_exc()}")
        sys.exit(1)

    logger.info(
        "The process to build and generate the application package finished with success."
    )
    sys.exit(0)
