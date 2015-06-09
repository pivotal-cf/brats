require 'bundler/setup'
require 'machete'
require 'machete/matchers'
require 'open-uri'
require 'json'
require 'fileutils'
require 'yaml'

`mkdir -p log`
Machete.logger = Machete::Logger.new("log/integration.log")

def parsed_manifest(buildpack:, branch: 'master')
  manifest_url = "https://raw.githubusercontent.com/cloudfoundry/#{buildpack}-buildpack/#{branch}/manifest.yml"
  YAML.load(open(manifest_url))
end

def install_buildpack(buildpack:, branch: 'master')
  FileUtils.mkdir_p('tmp')
  ` set -e
    git clone -q -b #{branch} --depth 1 --recursive https://github.com/cloudfoundry/#{buildpack}-buildpack tmp/#{buildpack}-buildpack
    cd tmp/#{buildpack}-buildpack
    export BUNDLE_GEMFILE=cf.Gemfile
    bundle install
    bundle exec buildpack-packager cached
    cf delete-buildpack #{buildpack}-brat-buildpack -f
    cf create-buildpack #{buildpack}-brat-buildpack $(ls *_buildpack-cached*.zip | head -n 1) 100 --enable
  `
end


def cleanup_buildpack(buildpack:)
  `
    rm -Rf tmp/#{buildpack}-buildpack
    cf delete-buildpack #{buildpack}-brat-buildpack -f
  `
end
