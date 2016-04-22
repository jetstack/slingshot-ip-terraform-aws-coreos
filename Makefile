TYPE=ip
NAME=vagrant-coreos

test:
	tar cf - vagrant/ | docker run --rm -i ruby:2.3 /bin/sh -c  "tar xf - && cd vagrant && bundle install --path vendor/path && bundle exec rspec"

build:
	docker build -t simonswine/slingshot-${TYPE}-${NAME} .
	docker build -t slingshot/${TYPE}-${NAME} .
