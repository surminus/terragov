# Terragov

[![Build Status](https://travis-ci.org/surminus/terragov.svg?branch=master)](https://travis-ci.org/surminus/terragov) [![Gem Version](https://badge.fury.io/rb/terragov.svg)](https://badge.fury.io/rb/terragov) [![Coverage Status](https://coveralls.io/repos/github/surminus/terragov/badge.svg?branch=master)](https://coveralls.io/github/surminus/terragov?branch=master)

![Terragov](https://github.com/surminus/terragov/blob/master/bricktop.jpg "Terrible pun, guv")

GOV.UK use [Terraform](https://terraform.io) to deploy infrastructure. Originally a lightweight bash script was built to support our opinionated Terraform project structure, but it quickly added further functionality and I decided it would be nicer to use a tool written in a more complete language.

## Installation

`gem install terragov`

## Project structure

This tool is only meant to be used specifically against the project structure [defined here](https://github.com/alphagov/govuk-aws/blob/cd28b00f6e1efb77e98c59ee8f92813e8f3278d1/doc/architecture/decisions/0010-terraform-directory-structure.md).

## Usage

`terragov [CMD] [OPTIONS]`

Run `--help` for details.

There are several **required** arguments to pass when running `apply`, `plan` or `destroy`:

Argument | Description
--- | ---
`stack` | Name of the stack you're deploying to
`environment` | Which environment to deploy to
`repo_dir` | The root of the repo containing terraform code
`data_dir` | The directory containing data
`project` | Name of the project you're deploying

## Configuration

There are three ways to pass arguments, detailed below.

### CLI options

Use command line flags to pass the relevant argument. This has **highest** precedence.

### Environment variables

Every command has an environment variable which can also be set. This has **second highest** precedence. The value is the name, in upper case, and prefixed with `TERRAGOV`. For example, to set `environment`:

`export TERRAGOV_ENVIRONMENT=integration`

### Configuration file

Specify a configuration file with the `-c` or `--config-file` flags, or use `TERRAGOV_CONFIG_FILE` to set the location of the file.

If environment variables or CLI flags are set, they will be overridden.

The contents should be YAML, and look like the following:

```
---
environment: 'integration'
stack: 'blue'
repo_dir: '~/govuk/govuk-aws'
data_dir: '~/govuk/govuk-aws-data/data'
```

## Optional global arguments

These may be set in the same way as described above, with the same precedence, but they are not required.

Argument | Description
--- | ---
`verbose` | Be more noisy
`dryrun` | CLI option is `--dry-run`, but config file and env var is `dryrun` and `TERRAGOV_DRYRUN` respectively
`skip_git_check` | Do not compare branches between the repo and data directories

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/surminus/terragov. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

