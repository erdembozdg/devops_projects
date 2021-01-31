#!/bin/bash

CI_ENV="${CI_ENV:-jenkins_env}"
SERVER_IP="${SERVER_IP:-134.122.42.254}"
SSH_USER="${SSH_USER:-root}"
KEY_USER="${KEY_USER:-jenkins}"

function init () {
  echo "Adding ${KEY_USER}"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
adduser -q --disabled-password --gecos  \"\" ${KEY_USER}
apt-get update && apt-get install -y -q sudo
adduser ${KEY_USER} sudo
  '"

  echo "Configuring sudo..."
  scp "conf/sudoers" "${SSH_USER}@${SERVER_IP}:/tmp/sudoers"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo chmod 440 /tmp/sudoers
sudo chown root:root /tmp/sudoers
sudo mv /tmp/sudoers /etc
  '"

  echo "Adding SSH key..."
  cat "$HOME/.ssh/id_rsa.pub" | ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
mkdir /home/${KEY_USER}/.ssh
cat >> /home/${KEY_USER}/.ssh/authorized_keys
  '"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
chmod 700 /home/${KEY_USER}/.ssh
chmod 640 /home/${KEY_USER}/.ssh/authorized_keys
sudo chown ${KEY_USER}:${KEY_USER} -R /home/${KEY_USER}/.ssh
  '"

  echo "Copying ${CI_ENV} files"
  scp -r "${CI_ENV}" "${SSH_USER}@${SERVER_IP}:/var"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
mkdir -p /var/${CI_ENV}/jenkins_home
chown -R jenkins:jenkins /var/${CI_ENV}
  '"
}

function git_init () {
  echo "Initialize git repo and hooks..."
  scp "jenkins_env/git/post-receive" "${SSH_USER}@${SERVER_IP}:/tmp/post-receive"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo apt-get update && sudo apt-get install -y -q git
sudo rm -rf /var/git/maven_dsl.git /var/git/maven_dsl
sudo mkdir -p /var/git/maven_dsl.git /var/git/maven_dsl 
sudo git --git-dir=/var/git/maven_dsl.git --bare init

sudo mv /tmp/post-receive /var/git/maven_dsl.git/hooks/post-receive
sudo chmod +x /var/git/maven_dsl.git/hooks/post-receive
sudo chown ${KEY_USER}:${KEY_USER} -R /var/git/maven_dsl.git /var/git/maven_dsl
  '"
}

function docker_init () {
  echo "Configuring Docker..."
  ssh "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo apt-get update && apt-get install -y curl && apt-get install -y -q git
curl -fsSL https://get.docker.com -o get-docker.sh
curl -L 'https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)' \
-o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
sh get-docker.sh
rm get-docker.sh
sudo usermod -aG docker ${KEY_USER}
chown jenkins:docker /var/run/docker.sock
    '"
  ssh -t "${SSH_USER}@${SERVER_IP}" bash -c "'sudo systemctl restart docker'"
}

while [[ $# -gt 0 ]]
do
case "$1" in
  -i|--init)
  init
  shift
  ;;
  -g|--git_init)
  git_init
  shift
  ;;
  -d|--docker_init)
  docker_init
  shift
  ;;
  *)
  echo "${1} is not a valid param"
  ;;
esac
shift
done