#!/bin/bash

mysqld &
cd /project
gem install bundler

if [ "$1" == "" ]; then
  bundle install
  (cd test/dummy && rm db/migrate/*)
  (cd test/dummy && rake knifeswitch:create_migrations)
  (cd test/dummy && rake db:create db:migrate)
  bin/test
else
  $*
fi
