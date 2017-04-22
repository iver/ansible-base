SHELL := bash
ACTUAL := $(shell pwd)

export ACTUAL

install:
	./shell/setup/setup.sh;

roles:
	./shell/setup/roles.sh;

run:
	ansible-playbook -i inventories/develop.ini plays/webservers.yml;
