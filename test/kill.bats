#!/usr/bin/env bats
teardown() {
  bundle exec bin/spoon -c test/spoon_config --force -d test11999199 || true
}

@test "Kill a container" {
  run bundle exec bin/spoon -c test/spoon_config test11999199 --nologin
  [ "$status" -eq 0 ]
  run bundle exec bin/spoon -c test/spoon_config --kill test11999199
  [ "$status" -eq 0 ]
  [ "$output" = "Container spoon-test11999199 killed" ]
  run bundle exec bin/spoon -c test/spoon_config -l
  [ "$status" -eq 0 ]
  [[ "${lines[1]}" =~ "test11999199 [ Stopped ] " ]]
  run bundle exec bin/spoon -c test/spoon_config --force -d test11999199
}

