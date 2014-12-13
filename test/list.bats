#!/usr/bin/env bats
teardown() {
  bundle exec bin/spoon -c test/spoon_config --force -d test11999199 || true
}

@test "No running containers" {
  run bundle exec bin/spoon -c test/spoon_config -l
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "List of available spoon containers:" ]
  [ "${lines[1]}" = "No spoon containers running at tcp://192.168.1.3:2375" ]
}

@test "Create a container & list containers" {
  run bundle exec bin/spoon -c test/spoon_config test11999199 --nologin
  [ "$status" -eq 0 ]
  run bundle exec bin/spoon -c test/spoon_config -l
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "List of available spoon containers:" ]
  run bundle exec bin/spoon -c test/spoon_config --force -d test11999199
}
