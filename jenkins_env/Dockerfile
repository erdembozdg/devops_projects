FROM jenkins/jenkins:lts

USER root

# Install Docker
# cat /etc/group | grep docker (998)
RUN mkdir -p /tmp/download && \
 curl -L https://download.docker.com/linux/static/stable/x86_64/docker-18.03.1-ce.tgz | tar -xz -C /tmp/download && \
 rm -rf /tmp/download/docker/dockerd && \
 mv /tmp/download/docker/docker* /usr/local/bin/ && \
 rm -rf /tmp/download && \
 groupadd -g 998 docker && \ 
 usermod -aG docker jenkins

RUN mkdir -p /home/jenkins/.ssh && chmod 700 /home/jenkins/.ssh 
COPY  ../conf/id_rsa.pub  /home/jenkins/.ssh/authorized_keys

RUN chown jenkins:jenkins   -R /home/jenkins && \
 chmod 400 /home/jenkins/.ssh/authorized_keys

# Docker Compose
# RUN curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" && \
#  -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose

USER jenkins