#!/usr/bin/env ruby
# This script is designed to analyze a Terraform project and
# identify all files with outdated modules. Each file with an
# outdated module reference is listed along with the proposed
# version update to be made.

require "CGI"
require "set"

require "dependabot/file_fetchers"
require "dependabot/file_parsers"
require "dependabot/update_checkers"
require "dependabot/file_updaters"
require "dependabot/pull_request_creator"
require "dependabot/omnibus"

$stdout.sync = true

# Utilize the github env variable per default
repo_name = ENV["GITHUB_REPOSITORY"]
if repo_name.empty?
  print "GITHUB_REPOSITORY needs to be set"
  exit(1)
end

# Directory where the base dependency files are.
directory = ENV["INPUT_DIRECTORY"] || "/"
directory = directory.gsub(/\\n/, "\n")
if directory.empty?
  print "The directory needs to be set"
  exit(1)
end

# Define the target branch
target_branch = ENV["GITHUB_HEAD_REF"]
if target_branch.empty?
  target_branch=nil
end

# Token to be used for fetching repository files
repo_token = ENV["INPUT_TOKEN"]
if repo_token.empty?
  print "A github token needs to be provided"
  exit(1)
end

credentials_repository = [
  {
    "type" => "git_source",
    "host" => "github.com",
    "username" => "x-access-token",
    "password" => repo_token
  }
]

credentials_dependencies = []

# Token to be used for fetching dependencies from github
dependency_token = ENV["INPUT_GITHUB_DEPENDENCY_TOKEN"]
unless dependency_token.empty?
  credentials_dependencies.push(
    {
      "type" => "git_source",
      "host" => "github.com",
      "username" => "x-access-token",
      "password" => dependency_token
    }
  )
end

def update(source, credentials_repository, credentials_dependencies)
  required_updates = []

  # Hardcode the package manager to terraform
  package_manager = "terraform"

  ##############################
  # Fetch the dependency files #
  ##############################
  fetcher = Dependabot::FileFetchers.for_package_manager(package_manager).new(
    source: source,
    credentials: credentials_repository,
  )

  files = fetcher.files
  commit = fetcher.commit

  ##############################
  # Parse the dependency files #
  ##############################
  parser = Dependabot::FileParsers.for_package_manager(package_manager).new(
    dependency_files: files,
    source: source,
    credentials: credentials_repository,
  )

  dependencies = parser.parse

  dependencies.select(&:top_level?).each do |dep|
    #########################################
    # Get update details for the dependency #
    #########################################
    checker = Dependabot::UpdateCheckers.for_package_manager(package_manager).new(
      dependency: dep,
      dependency_files: files,
      credentials: credentials_dependencies,
    )

    next if checker.up_to_date?

    requirements_to_unlock =
      if !checker.requirements_unlocked_or_can_be?
        if checker.can_update?(requirements_to_unlock: :none) then :none
        else :update_not_possible
        end
      elsif checker.can_update?(requirements_to_unlock: :own) then :own
      elsif checker.can_update?(requirements_to_unlock: :all) then :all
      else :update_not_possible
      end

    next if requirements_to_unlock == :update_not_possible

    updated_deps = checker.updated_dependencies(
      requirements_to_unlock: requirements_to_unlock
    )
    updated_deps.each do |updated_dep|
        required_updates << "File #{source.directory}/#{updated_dep.requirements[0][:file]} needs module #{updated_dep.requirements[0][:source][:url]} updated from #{updated_dep.previous_version} to #{updated_dep.version}"
    end
  end
  return required_updates
end

directory_updates = Array.new

directory.split("\n").each do |dir|
  source = Dependabot::Source.new(
    provider: "github",
    repo: repo_name,
    directory: dir.strip,
    branch: target_branch,
  )
  directory_updates.concat(update(source, credentials_repository, credentials_dependencies))
end

if directory_updates.empty?
  puts "All modules are up to date"
else
  output = "Modules are not up to date\n"
  output += SortedSet.new(directory_updates).to_a().join("\n")
  if ENV['GITHUB_ACTIONS']
    puts output
    puts "::set-output name=message::#{CGI.escape(output)}"
  else
    puts output
  end
  exit!
end
