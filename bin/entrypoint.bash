#!/bin/bash

mysqld &
cd /project
gem install bundler

if [ "$1" == "" ]; then
  bundle install
  (cd test/dummy && rm -f db/migrate/*)
  (cd test/dummy && bundle exec rake knifeswitch:create_migrations)
  (cd test/dummy && bundle exec rake db:create db:migrate)
  bin/test
else
  $*
fi
