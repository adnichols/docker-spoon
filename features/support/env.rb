require 'aruba/cucumber'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)),'..','..','lib')

Before do
  @aruba_timeout_seconds = 30
  # Using "announce" causes massive warnings on 1.9.2
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
end

After do
  ENV['RUBYLIB'] = @original_rubylib
end

Before('@container_clean') do
  run_simple('spoon --url tcp://127.0.0.1:2375 -d testcontainer19919 --force || true')
end

After('@container_clean') do
  run_simple('spoon --url tcp://127.0.0.1:2375 -d testcontainer19919 --force || true')
end

Before('@docker_config_test') do
  ENV['DOCKER_HOST'] = 'tcp://127.0.0.1:2375'
end
