def dump_load_path
  puts $LOAD_PATH.join("\n")
  found = nil
  $LOAD_PATH.each do |path|
    if File.exists?(File.join(path,"rspec"))
      puts "Found rspec in #{path}"
      if File.exists?(File.join(path,"rspec","core"))
        puts "Found core"
        if File.exists?(File.join(path,"rspec","core","rake_task"))
          puts "Found rake_task"
          found = path
        else
          puts "!! no rake_task"
        end
      else
        puts "!!! no core"
      end
    end
  end
  if found.nil?
    puts "Didn't find rspec/core/rake_task anywhere"
  else
    puts "Found in #{path}"
  end
end
require 'bundler'
require 'rspec/core/rake_task'
require 'rake/clean'
require 'cucumber'
require 'cucumber/rake/task'

include Rake::DSL

Bundler::GemHelper.install_tasks

CUKE_RESULTS = 'results.html'
CLEAN << CUKE_RESULTS
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format html -o #{CUKE_RESULTS} --format pretty --no-source -x"
  t.fork = false
end

task(:testsetup) do
  cmd = 'bundle exec bin/spoon --url tcp://127.0.0.1:2375 --build --builddir docker --image spoon_test'
  sh(cmd)
end

RSpec::Core::RakeTask.new(:spec)

task :default => [:features]

