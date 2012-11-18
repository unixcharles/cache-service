#!/usr/bin/env rake
require 'rspec/core/rake_task'
require 'cane/rake_task'

desc "Run the specs"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ['--options', "spec/spec.opts"]
end

desc "Run cane to check quality metrics"
Cane::RakeTask.new(:quality) do |cane|
  cane.style_measure = 90
  cane.abc_max = 10
  cane.max_violations = 1
  cane.add_threshold 'coverage/covered_percent', :>=, 90
  cane.no_doc = true
end

desc "Test coverage report"
task :coverage => :spec do
  `open coverage/index.html`
end

task :default => [:spec, :quality]