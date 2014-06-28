FROM ubuntu:14.04

RUN locale-gen en_US.UTF-8
RUN apt-get update
RUN apt-get install -y python-software-properties
RUN apt-get install -y software-properties-common 
RUN apt-get install -y python-setuptools 
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update
RUN apt-get install -y zip 
RUN apt-get install -y openssl
RUN apt-get install -y git 
RUN apt-get install -y emacs24 
RUN apt-get install -y tmux 
RUN apt-get install -y ack-grep 
RUN apt-get install -y python 
RUN apt-get install -y wget 
RUN apt-get install -y xsel 
RUN apt-get install -y python-pip 
RUN apt-get install -y zsh 
RUN apt-get install -y curl 
RUN apt-get install -y build-essential 
RUN apt-get install -y runit 
RUN apt-get install -y openssh-server 
RUN apt-get install -y ruby 
RUN apt-get install -y tree
RUN apt-get install -y vim

RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

RUN apt-get -y install oracle-java7-installer

RUN easy_install httpie
RUN pip install https://github.com/Lokaltog/powerline/tarball/develop

RUN mkdir -p /etc/service
ADD resources /etc/service/ssh
ADD runit /etc/runit

RUN mkdir -p /var/run/sshd

RUN useradd -s /bin/zsh -m -d /home/pairing -g root pairing
RUN echo "pairing:pairing" | chpasswd
RUN echo "pairing        ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ADD resources/zshrc.default /home/pairing/.zshrc

RUN mkdir /home/pairing/projects

EXPOSE 22

ENTRYPOINT "/usr/sbin/runit"
