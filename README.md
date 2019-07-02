this project Contain a docker container with rundeck (a web interface to manage access and make tasks to ansible), ansible and some useful modules

execute the following command to init this container

#docker run -d -p 4440:4440 -p 2222:22 -e "external_ip=x.x.x.x" -t mprebello/rundeck-ansible-standalone
