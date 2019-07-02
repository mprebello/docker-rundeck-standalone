#!/bin/bash
function main() {
  done_file=/etc/.done
  if [ ! -e done_file ]
  then
    ansible_default_dirs="/etc/ansible /etc/ansible/roles /etc/ansible/group_vars"
    ansible_roles_src_dir="/usr/src/ansible-modules-scripts/code"
    ansible_roles_src_vars_dir="/usr/src/default_variables"
    ansible_conf_dir="/etc/ansible"
    createDefaultFolder
    syncRoles
    copyDefaultVariablesPython
    alreadyDone
    configureRundeckServer
  fi
  initSshDaemon
  initJavaServer
}

function alreadyDone() {
  echo "done" >/etc/.done
}

function createDefaultFolder() {
  for dir_now in ${ansible_default_dirs}
  do
    if [ ! -e ${dir_now} ]
    then
      mkdir ${dir_now}
    fi
  done
}

function copyDefaultVariablesPython(){
  variables="roles/CommonTasks/scripts/Information/openticket.csv "
  variables+="roles/CommonTasks/scripts/ManageHostDetails/config_vars_host_details.py "
  variables+="roles/CommonTasks/scripts/ManageReport/report_config_vars.py "
  variables+="roles/CommonTasks/scripts/ManageWarpTicket/config_vars.py "
  variables+="roles/CommonTasks/scripts/SendMail/config_vars.py "
  variables+="roles/CommonTasks/vars/main.yml "
  variables+="hosts "
  variables+="ansible.cfg "
  variables+="group_vars/linux-example.yml "
  variables+="group_vars/windowslocal-example.yml "
  variables+="group_vars/windowsdomain-example.yml "

  for variable in ${variables}
  do
    if [ ! -e  ${ansible_conf_dir}/${variable} ]
    then
      cp ${ansible_roles_src_vars_dir}/${variable} ${ansible_conf_dir}/${variable}
    fi
  done
}

function syncRoles(){
  rsync -a ${ansible_roles_src_dir}/* ${ansible_conf_dir}/roles/
}

function initSshDaemon(){
  mkdir -p /var/run/sshd
  service ssh start
}

function configureRundeckServer(){
  files_to_change=$(grep -l I_NEED_TO_CHANGE_MY_HOSTNAME_HERE /var/rundeck_app -R | uniq)
  for file in $files_to_change
  do
   sed -i "s/I_NEED_TO_CHANGE_MY_HOSTNAME_HERE/$HOSTNAME/g" $file
  done

  if [ "${external_ip}" == "" ]
  then
    external_ip="$HOSTNAME"
  fi

  files_to_change=$(grep -l I_NEED_TO_CHANGE_MY_EXTERNAL_IP_HERE /var/rundeck_app -R | uniq)
  for file in $files_to_change
  do
   sed -i "s/I_NEED_TO_CHANGE_MY_EXTERNAL_IP_HERE/${external_ip}/g" $file
  done

}

function initJavaServer(){
  chown rundeck:rundeck /var/rundeck_app -R
  su rundeck -c "java -Xmx2g -jar /var/rundeck_app/rundeck.war"
}

main
