Feature: spoon provides help as necessary

  Scenario: App provides help

    When I run `spoon --help`
    Then the exit status should be 0
		And the output should contain "--version"
    And the output should contain "--list"
    And the output should contain "--destroy"
    And the output should contain "--build"
    And the output should contain "--builddir"
    And the output should contain "--url"
    And the output should contain "--list-images"
    And the output should contain "--image"
    And the output should contain "--network"
    And the output should contain "--prefix"
    And the output should contain "--config"
    And the output should contain "--debug"
		And the output should contain "--debugssh"
		And the output should contain "--force"

	Scenario: Missing arguments throw error

		When I run `spoon --builddir`
		Then the exit status should be 1
		And the output should contain "missing argument:"

		When I run `spoon --config`
		Then the exit status should be 1
		And the output should contain "missing argument:"

		When I run `spoon --destroy`
		Then the exit status should be 1
		And the output should contain "missing argument:"

		When I run `spoon --image`
		Then the exit status should be 1
		And the output should contain "missing argument:"

		When I run `spoon --kill`
		Then the exit status should be 1
		And the output should contain "missing argument:"

		When I run `spoon --network`
		Then the exit status should be 1
		And the output should contain "missing argument:"

		When I run `spoon --portforwards`
		Then the exit status should be 1
		And the output should contain "missing argument:"

		When I run `spoon --ports`
		Then the exit status should be 1
		And the output should contain "missing argument:"

		When I run `spoon --prefix`
		Then the exit status should be 1
		And the output should contain "missing argument:"

		When I run `spoon --restart`
		Then the exit status should be 1
		And the output should contain "missing argument:"

		When I run `spoon --url`
		Then the exit status should be 1
		And the output should contain "missing argument:"

