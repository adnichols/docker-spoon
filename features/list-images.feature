@build
Feature: Test listing of images

  Scenario: As a user of spoon I should be able to list images

		Given a file named "spoon_config" with:
		"""
		options[:url] = "tcp://127.0.0.1:2375"
		options[:image] = "spoon_test"
		"""

		When I run `spoon -c spoon_config --list-images`
		Then the exit status should be 0
		And the output should contain:
		"""
		Image: ["spoon_test:latest"]
		"""
