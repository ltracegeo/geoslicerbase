# Contributing to GeoSlicerBase

First off, thank you for considering contributing to GeoSlicerBase!

This document is a guide to help you through the process. We have a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

## Code of Conduct

This project and everyone participating in it is governed by the [GeoSlicer Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior.

## How Can I Contribute?

There are many ways to contribute to GeoSlicer, from writing tutorials or blog posts, improving the documentation, submitting bug reports and feature requests or writing code which can be incorporated into GeoSlicer itself.

### Reporting Bugs

Bugs are tracked as [GitHub issues](https://github.com/ltracegeo/geoslicerbase/issues). Before creating a bug report, please check the list of existing issues to see if the bug has already been reported. If it has, please add a comment to the existing issue instead of creating a new one.

When you are creating a bug report, please include as many details as possible. Fill out the required template, the information it asks for helps us resolve issues faster.

### Suggesting Enhancements

Enhancement suggestions are tracked as [GitHub issues](https://github.com/ltracegeo/geoslicerbase/issues). Before creating an enhancement suggestion, please check the list of existing issues to see if the enhancement has already been suggested. If it has, please add a comment to the existing issue instead of creating a new one.

When you are creating an enhancement suggestion, please include as many details as possible. Fill out the required template, the information it asks for helps us to better understand the enhancement.

### Submitting Pull Requests

If you have a bugfix or a new feature that you would like to contribute to GeoSlicerBase, you can do so by sending a pull request. We are always thrilled to receive pull requests, and do our best to process them as fast as we can. Before you start to code, we recommend discussing your plans through a GitHub issue, especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.

#### Pull Request Workflow

1.  **Fork the repository** and create your branch from `master`.
2.  **Set up your development environment** by following the instructions in the [BUILD.md](BUILD.md) file.
3.  **Make your changes.**
4.  **Run the test suite** to ensure that your changes don't break anything.
    - [Linux instructions](https://slicer.readthedocs.io/en/latest/developer_guide/build_instructions/linux.html#test-slicer)
    - [Windows instructions](https://slicer.readthedocs.io/en/latest/developer_guide/build_instructions/windows.html#test-slicer)
5.  **Commit your changes** using a descriptive commit message that follows our [commit message conventions](#commit-message-conventions).
6.  **Push your branch** to your fork.
7.  **Open a pull request** to the `master` branch of the main repository.

### Style Guides
 
#### Commit Message Conventions

We use the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification for our commit messages. This allows us to automatically generate changelogs and release notes. Please follow this specification for your commit messages.

Here are some examples:

*   `feat: Add new feature`
*   `fix: Fix bug`
*   `docs: Update documentation`
*   `style: Format code`
*   `refactor: Refactor code`
*   `test: Add tests`
*   `chore: Update build scripts`


### Code Style
Follow the [3D Slicer Style Guide](https://slicer.readthedocs.io/en/latest/developer_guide/style_guide.html) for C++ and Python code.
 