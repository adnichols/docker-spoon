require 'aruba/cucumber'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)),'..','..','lib')
C_NAME = "testcontainer19919"
URL = "tcp://127.0.0.1:2375"
IMAGE = "spoon_test"

Before do
  @aruba_timeout_seconds = 10
  # Using "announce" causes massive warnings on 1.9.2
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
end

After do
  ENV['RUBYLIB'] = @original_rubylib
end

Before('@clean') do
  run_simple("spoon --url #{URL} -d #{C_NAME} --force")
end

After('@clean') do
  run_simple("spoon --url #{URL} -d #{C_NAME} --force")
end

Before('@docker_env') do
  ENV['DOCKER_HOST'] = URL
end

Before('@build') do
  run_simple("spoon --url #{URL} --image #{IMAGE} --build --builddir ../../docker")
end

Before('@interact') do
  @aruba_io_wait_seconds = 5
end
