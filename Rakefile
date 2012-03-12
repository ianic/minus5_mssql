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


desc "build gem and deploy to gems.minus5.hr"
task :deploy => [:gem] do
  file = "pkg/minus5_mssql-#{GEMSPEC.version}.gem"
  print "installing\n"
  `gem install #{file} --no-rdoc --no-ri`
  print "copying to gems.minus5.hr\n"
  `scp #{file} gems.minus5.hr:/var/www/apps/gems/gems`
  print "updating gem server index\n"
  `ssh ianic@gems.minus5.hr "cd /var/www/apps/gems; sudo gem generate_index"`
end
