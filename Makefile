TYPE=ip
NAME=vagrant-coreos

build:
	docker build -t simonswine/slingshot-${TYPE}-${NAME} .
	docker build -t slingshot/${TYPE}-${NAME} .
