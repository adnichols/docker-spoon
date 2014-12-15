@build @clean 
Feature: Test ssh port forward specification

  Scenario: portforwards defined in config file with single port

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		options[:portforwards] = [ "19919" ]
		"""

		When I run `spoon -c spoon_config testcontainer19919 --nologin`
		Then the exit status should be 0
		And the output should contain:
		"""
		SSH Forwards: -L 19919:127.0.0.1:19919
		"""

	Scenario: portforwards defined on command line with dynamic mapping

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		"""

		When I run `spoon -c spoon_config testcontainer19919 --portforwards 19919 --nologin`
		Then the exit status should be 0
		And the output should contain:
		"""
		SSH Forwards: -L 19919:127.0.0.1:19919
		"""

  Scenario: portforwards defined in config file with different rport

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		options[:portforwards] = [ '19919:19918' ]
		"""

		When I run `spoon -c spoon_config testcontainer19919 --nologin`
		Then the exit status should be 0
		And the output should contain:
		"""
		SSH Forwards: -L 19919:127.0.0.1:19918
		"""

	Scenario: portforwards defined on command line with different rport

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		"""

		When I run `spoon -c spoon_config testcontainer19919 --portforwards 19919:19918 --nologin`
		Then the exit status should be 0
		And the output should contain:
		"""
		SSH Forwards: -L 19919:127.0.0.1:19918
		"""

	Scenario: Multiple portforwards defined

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		"""

		When I run `spoon -c spoon_config testcontainer19919 --portforwards 19919,18818 --nologin`
		Then the exit status should be 0
		And the output should contain:
		"""
		SSH Forwards: -L 19919:127.0.0.1:19919 -L 18818:127.0.0.1:18818
		"""

	Scenario: Multiple portforwards defined with different rport

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		"""

		When I run `spoon -c spoon_config testcontainer19919 --portforwards 19919:19918,18818:18819 --nologin`
		Then the exit status should be 0
		And the output should contain:
		"""
		SSH Forwards: -L 19919:127.0.0.1:19918 -L 18818:127.0.0.1:18819
		"""
