require 'aruba'
require 'aruba/api'
require 'pathname'

include Aruba::Api

root = Pathname.new(__FILE__).parent.parent

ENV['PATH'] = "#{root.join('bin').to_s}#{File::PATH_SEPARATOR}#{ENV['PATH']}"

describe "spoon" do
  describe "Help output" do
    it "should provide help when --help is passed" do
      run_simple "spoon --help"

      assert_exit_status(0)

    end
  end
end
