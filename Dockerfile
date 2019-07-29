FROM ruby:2.6.3-stretch

RUN wget https://dev.mysql.com/get/mysql-apt-config_0.8.9-1_all.deb
RUN apt-get update
RUN apt-get install -y lsb-release
RUN dpkg -i mysql-apt-config_0.8.9-1_all.deb
RUN apt-get update
RUN apt-get install -y mysql-server

RUN mkdir             /var/run/mysqld
RUN chown mysql:mysql /var/run/mysqld

ENV RAILS_ENV=test

COPY bin/entrypoint.bash /entrypoint.bash
RUN chmod +x /entrypoint.bash

ENTRYPOINT ["/entrypoint.bash"]
