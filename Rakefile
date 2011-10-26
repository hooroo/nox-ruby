require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new(:spec) do |t|
  t.libs << "libs"
  t.libs << "specs"
  t.test_files = FileList['specs/**/*_spec.rb']
  t.verbose = false
end

desc "Run specs"
task :default => :spec
