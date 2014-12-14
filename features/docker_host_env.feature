@docker_env
Feature: Validate URL Config

  Scenario: Use DOCKER_HOST

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2376"
		options[:image] = "spoon_test"
		"""

		When I run `spoon -c /dev/null -l`
		Then the exit status should be 0
		And the output should contain:
		"""
		No spoon containers running at tcp://127.0.0.1:2375
		"""

		When I run `spoon -c spoon_config -l`
		Then the exit status should be 1
		And the output should contain:
		"""
		Connection refused
		"""
