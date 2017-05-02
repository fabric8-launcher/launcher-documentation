FROM centos:latest

#FROM maven:3.2-jdk-7

MAINTAINER Zach Rhoads (https://github.com/rhoads-zach)

USER root

# Install asciidoctor
RUN yum install -y wget && \
    wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo && \
    yum install -y rubygems apache-maven which git ruby-devel gcc make.x86_64 && \
    gem install asciidoctor && \
    yum clean all