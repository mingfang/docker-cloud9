FROM ubuntu:14.04
  
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    TERM=xterm
RUN locale-gen en_US en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc
RUN apt-get update

# Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

# Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc

RUN apt-get install -y build-essential
RUN apt-get install -y nginx

#Node
RUN wget -O - https://nodejs.org/download/release/v0.12.13/node-v0.12.13-linux-x64.tar.gz | tar xz
RUN mv node* node && \
    ln -s /node/bin/node /usr/local/bin/node && \
    ln -s /node/bin/npm /usr/local/bin/npm
ENV NODE_PATH /usr/local/lib/node_modules

#NPM Modules
RUN npm install -g gulp npm-check-updates slush slush-generator

#Change last_commit hash as a cache buster
ENV latest_commit b70a6ab4752b50f18962b12d01cd6044b84c8316
RUN git clone --depth 1 https://github.com/c9/core.git
RUN cd core && \
    npm install && \
    ./scripts/install-sdk.sh

#ssl
RUN mkdir -p /etc/nginx/ssl && \
    cd /etc/nginx/ssl && \
    export PASSPHRASE=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 128; echo) && \
    openssl genrsa -des3 -out server.key -passout env:PASSPHRASE 2048 && \
    openssl req -new -batch -key server.key -out server.csr -subj "/C=/ST=/O=org/localityName=/commonName=org/organizationalUnitName=org/emailAddress=/" -passin env:PASSPHRASE && \
    openssl rsa -in server.key -out server.key -passin env:PASSPHRASE && \
    openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt

#Set your user:password
RUN echo "user:`perl -le 'print crypt(\"password\", \"salt-hash\")'`" > /etc/nginx/htpasswd
ADD default /etc/nginx/sites-enabled/default

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
