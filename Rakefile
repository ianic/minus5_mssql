require "rake/testtask"
require 'rubygems/package_task'
load 'minus5_mssql.gemspec'

task :default => [:test]

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = Dir[ "test/test_*.rb" ]
  test.verbose = true
end

Gem::PackageTask.new(GEMSPEC) do |pkg|
end
