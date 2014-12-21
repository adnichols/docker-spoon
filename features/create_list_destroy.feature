@build @clean
Feature: Creating, Listing, Killing, Restarting and Destroying containers works

  Scenario: Creating, Listing & Destroying containers works

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		options[:prefix] = "test-"
		"""

		When I run `spoon -c spoon_config -l`
		Then the exit status should be 0
		And the output should contain:
		"""
		No spoon containers running at tcp://127.0.0.1:2375
		"""

		When I run `spoon -c spoon_config testcontainer19919 --nologin`
		Then the exit status should be 0
		And the output should contain:
		"""
		The 'test-testcontainer19919' container doesn't exist, creating...
		"""

		When I run `spoon -c spoon_config -l`
		Then the exit status should be 0
		And the output should contain:
		"""
		List of available spoon containers:
		"""
		And the output should contain:
		"""
		testcontainer19919 [ Running ] spoon_test
		"""

		When I run `spoon -c spoon_config --kill testcontainer19919`
		Then the exit status should be 0
		And the output should contain:
		"""
		Container test-testcontainer19919 killed
		"""

		When I run `spoon -c spoon_config -l`
		Then the exit status should be 0
		And the output should contain:
		"""
		testcontainer19919 [ Stopped ] spoon_test
		"""

		When I run `spoon -c spoon_config --restart testcontainer19919`
		Then the exit status should be 0
		And the output should contain:
		"""
		Container test-testcontainer19919 restarted
		"""

		When I run `spoon -c spoon_config -l`
		Then the exit status should be 0
		And the output should contain:
		"""
		testcontainer19919 [ Running ] spoon_test
		"""

		When I run `spoon -c spoon_config -d testcontainer19919` interactively
		And I type "n"
		Then the exit status should be 0
		And the output should contain:
		"""
		Delete aborted..
		"""

		When I run `spoon -c spoon_config -d testcontainer19919` interactively
		And I type "y"
		Then the exit status should be 0
		And the output should contain:
		"""
		Destroying test-testcontainer19919
		Done!
		"""
