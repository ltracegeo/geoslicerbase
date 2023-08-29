""" Script to update CMakeLists.txt content dinamically for GeoSlicer base building process purposes.
"""


import argparse
import logging
import re
import sys
from pathlib import Path


# Default variables
REPO_FOLDER = Path(__file__).parent.parent
DEFAULT_REPO = "git@bitbucket.org:ltrace/slicer.git"


# Configure logger
logger = logging.getLogger(__name__)
logger.addHandler(logging.StreamHandler())
logger.setLevel(logging.INFO)


def get_slicersource_fetchcontent_populate_string(repo, commit_hash):
    return f"""FetchContent_Populate(slicersources
    GIT_REPOSITORY {repo}
    GIT_TAG {commit_hash}
    GIT_PROGRESS 1
    )"""


def process(args):
    cmakelists_file_path = REPO_FOLDER / "CMakeLists.txt"

    if not cmakelists_file_path.exists():
        raise RuntimeError(f"CMakeLists.txt not found at {REPO_FOLDER.as_posix()}")

    with open(cmakelists_file_path, "r") as file:
        data = file.read()

    if data is None:
        raise RuntimeError(f"The {cmakelists_file_path.as_posix()} is empty.")

    regex = r"(FetchContent_Populate(\s*|\S*)\((\s*|\S*)?slicersources(\s*|\S*)*\))"
    match = re.search(regex, data)
    if match is None:
        raise RuntimeError(
            f"Unable to find FetchContent_Populate related to the slicersources at {cmakelists_file_path.as_posix()}"
        )

    new_data = (
        data[: match.start()]
        + get_slicersource_fetchcontent_populate_string(repo=args.repository, commit_hash=args.commit)
        + data[match.end() :]
    )

    cmakelists_file_path.unlink()
    with open(cmakelists_file_path, "w") as file:
        file.write(new_data)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Apply dynamic changes to CMakeLists.txt")
    parser.add_argument("--commit", help="Specify the commit. Default to 'master' branch name.", default="master")
    parser.add_argument(
        "--repository",
        help="The external repository to fetch. Default to the ltrace/Slicer.git url.",
        default=DEFAULT_REPO,
    )

    args = parser.parse_args()

    if args.commit is None:
        raise AttributeError("The commit hash, tags name or branch name is missing! Aborting process...")
    if args.repository is None:
        raise AttributeError("The repository URL is missing! Aborting process...")

    try:
        logger.info(f"Starting process to update CMakeLists.txt...")
        process(args)
    except Exception as error:
        logger.info(f"Found a problem! Cancelling process...")
        logger.info(f"Error: {error}")
        sys.exit(1)

    logger.info("The changes were applied to the CMakeLists.txt successfully.")
    sys.exit(0)
