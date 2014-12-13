#!/usr/bin/env bats
teardown() {
  bundle exec bin/spoon -c test/spoon_config --force -d test11999199 || true
}

@test "Create a container & query network" {
  run bundle exec bin/spoon -c test/spoon_config test11999199 --nologin
  [ "$status" -eq 0 ]
  run bundle exec bin/spoon -c test/spoon_config -n test11999199
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Host: 192.168.1.3" ]
  [[ "${lines[1]}" =~ "22 ->" ]]
  run bundle exec bin/spoon -c test/spoon_config --force -d test11999199
}
