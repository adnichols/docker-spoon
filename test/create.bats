#!/usr/bin/env bats
teardown() {
  bundle exec bin/spoon -c test/spoon_config --force -d test11999199 || true
}

@test "Create & delete a container" {
  run bundle exec bin/spoon -c test/spoon_config test11999199 --nologin
  [ "$status" -eq 0 ]
  [ "$output" = "The 'spoon-test11999199' container doesn't exist, creating..." ]
  run bundle exec bin/spoon -c test/spoon_config --force -d test11999199
  [ "$status" -eq 0 ]
}
