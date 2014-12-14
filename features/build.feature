Feature: Test building

  Scenario: --build should fail with an invalid configuration

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		options[:builddir] = "."
		"""

		When I run `spoon -c spoon_config --build`
		Then the exit status should be 1
		And the output should contain:
		"""
		must contain a Dockerfile... cannot continue
		"""

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		options[:builddir] = "/tmp/this_18881_random_dir_should_not_exist"
		"""

		When I run `spoon -c spoon_config --build`
		Then the exit status should be 1
		And the output should contain:
		"""
		must contain a Dockerfile... cannot continue
		"""

	Scenario: --build should work with a valid configuration

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		options[:builddir] = "../../docker"
		"""

		When I run `spoon -c spoon_config --build`
		Then the exit status should be 0
		And the output should contain:
		"""
		Successfully built
		"""


