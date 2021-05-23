# terraform-module-versions-action
![license](https://img.shields.io/github/license/trumant/terraform-module-versions-action)
[![GitHub tag](https://img.shields.io/github/tag/trumant/terraform-module-versions-action.svg)](https://github.com/trumant/terraform-module-versions-action/tags)

Github action for identifying outdated module references in a Terraform project

## Introduction

This action checks all Terraform module references in a Terraform project to
identify, which if any are out of date. It will then provide guidance on which
module versions should be changed in each file.

## Usage

<!-- start usage -->
```yaml
- uses: trumant/terraform-module-versions-action@v1
  with:
    # Where to look for terraform files to check for dependency upgrades.
    # The directory is relative to the repository's root.
    # Multiple paths can be provided by splitting them with a new line.
    # Example:
    #   directory: |
    #     /path/to/first/module
    #     /path/to/second/module
    # Default: "/"
    directory: ''

    # Auth token used to push the changes back to github and create the pull request with.
    # [Learn more about creating and using encrypted secrets](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets)
    # default: ${{ github.token }}
    token: ''

    # Auth token used for checking terraform dependencies that are from github repositories.
    # Token requires read access to all modules that you want to automatically check for updates
    # [Learn more about creating and using encrypted secrets](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets)
    # default: ${{ github.token }}
    github_dependency_token:
```
<!-- end usage -->

## Examples

### Basic example 

In this basic example, the action will run against pull requests

```yaml
name: Check Terraform module versions
on:
  pull_request:

jobs:
  terraform-module-versions:
    runs-on: ubuntu-latest
    steps:
      - name: Check Terraform module versions
        uses: trumant/terraform-module-versions-action@v1
        with:
          github_dependency_token: ${{ secrets.DEPENDENCY_GITHUB_TOKEN }}
```

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)