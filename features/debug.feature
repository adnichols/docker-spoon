Feature: Test debug mode

  Scenario: Normally should not see any debugging output

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		"""

		When I run `spoon -c spoon_config -l`
		Then the exit status should be 0
		And the output should not contain "D: "

  Scenario: With --debug I should see debug output

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		"""

		When I run `spoon -c spoon_config -l --debug`
		Then the exit status should be 0
		And the output should contain "D: "
