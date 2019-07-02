FROM ubuntu:latest

MAINTAINER Marcel Rebello
ARG PrerequeriedToInstallRundeckServer="bash ca-certificates openssh-server sudo openssh-client mysql-client curl wget git rsync gpw openjdk-8-jre-headless ca-certificates-java supervisor procps uuid-runtime parallel vim"
ARG PrerequeriedToInstallAnsible="sshpass python python-pip python-all python2.7 python2.7-dev python2.7-minimal libkrb5-dev krb5-user"
ARG AnsibleModules="pywinrm pywinrm[kerberos] pywinrm[credssp] ansible==2.5.4 prettytable mysql-connector-python"
ARG AnsibleModulesScriptsRepository="https://github.com/mprebello/ansible-modules-scripts"
ARG RundeckWarRepository="https://dl.bintray.com/rundeck/rundeck-maven/rundeck-3.0.23-20190619.war"
ARG RundeckDir="/var/rundeck_app"
ARG RundeckWar="${RundeckDir}/rundeck.war"

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get -qqy install ${PrerequeriedToInstallRundeckServer} && \
    apt-get -qqy install ${PrerequeriedToInstallAnsible} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install ${AnsibleModules}

RUN cd /usr/src && \
    git clone ${AnsibleModulesScriptsRepository} ansible-modules-scripts

#CREATE USER TO RUN APPLICATION
RUN useradd rundeck -m -s /bin/bash

#COPY WAR
RUN export DEBIAN_FRONTEND=noninteractive && \
    mkdir -p ${RundeckDir} && \
    curl -Lo ${RundeckWar} ${RundeckWarRepository}

RUN  USER_NOW=admin && PASSWORD_NOW=admin && \
      useradd ${USER_NOW} -m && gpasswd -a ${USER_NOW} sudo && \
      RESULT=$(echo "${USER_NOW}:${PASSWORD_NOW}" | chpasswd) && \
      passwd -e ${USER_NOW} && \
      echo -e "USER:${USER_NOW} \nPASSWORD:${PASSWORD_NOW}"

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 4440 4443
VOLUME  ["/etc/rundeck", "/var/rundeck", "/var/lib/rundeck", "/var/lib/mysql", "/var/log/rundeck", "/opt/rundeck-plugins", "/var/lib/rundeck/logs", "/var/lib/rundeck/var/storage", "/etc/ansible"]

COPY content/ /
RUN chmod 755 /init.sh

ENTRYPOINT ["/init.sh"]
