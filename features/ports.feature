@container_clean
Feature: Test privileged mode

  Scenario: Ports defined in config file with dynamic mapping

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		options[:ports] = [ 19919 ]
		"""

		When I run `spoon -c spoon_config testcontainer19919 --nologin`
		Then the exit status should be 0

		When I run `spoon -c spoon_config -n testcontainer19919`
		Then the exit status should be 0
		And the output should contain:
		"""
		Host: 127.0.0.1
		"""
		And the output should contain "22 ->"
		And the output should contain "19919 -> 49"

	Scenario: Ports defined on command line with dynamic mapping

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		"""

		When I run `spoon -c spoon_config testcontainer19919 --ports 19919 --nologin`
		Then the exit status should be 0

		When I run `spoon -c spoon_config -n testcontainer19919`
		Then the exit status should be 0
		And the output should contain:
		"""
		Host: 127.0.0.1
		"""
		And the output should contain "22 ->"
		And the output should contain "19919 -> 49"

  Scenario: Ports defined in config file with static mapping

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		options[:ports] = [ '19919:19919' ]
		"""

		When I run `spoon -c spoon_config testcontainer19919 --nologin`
		Then the exit status should be 0

		When I run `spoon -c spoon_config -n testcontainer19919`
		Then the exit status should be 0
		And the output should contain:
		"""
		Host: 127.0.0.1
		"""
		And the output should contain "22 ->"
		And the output should contain "19919 -> 19919"

	Scenario: Ports defined on command line with static mapping

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		"""

		When I run `spoon -c spoon_config testcontainer19919 --ports 19919:19919 --nologin`
		Then the exit status should be 0

		When I run `spoon -c spoon_config -n testcontainer19919`
		Then the exit status should be 0
		And the output should contain:
		"""
		Host: 127.0.0.1
		"""
		And the output should contain "22 ->"
		And the output should contain "19919 -> 19919"
