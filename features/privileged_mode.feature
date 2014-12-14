@build @clean
Feature: Test privileged mode

  Scenario: Privileged mode defined in config file

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		options[:privileged] = true
		"""

		When I run `spoon -c spoon_config testcontainer19919 --nologin`
		Then the exit status should be 0

		When I run `docker inspect spoon-testcontainer19919`
		Then the output should contain:
		"""
		"Privileged": true,
		"""

	Scenario: Privileged mode defined on command line

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		options[:privileged] = false
		"""

		When I run `spoon -c spoon_config testcontainer19919 --nologin --privileged`
		Then the exit status should be 0

		When I run `docker inspect spoon-testcontainer19919`
		Then the output should contain:
		"""
		"Privileged": true,
		"""

	Scenario: Privileged mode not defined

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		"""

		When I run `spoon -c spoon_config testcontainer19919 --nologin`
		Then the exit status should be 0

		When I run `docker inspect spoon-testcontainer19919`
		Then the output should contain:
		"""
		"Privileged": false,
		"""
