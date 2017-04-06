FROM openshift/jenkins-slave-maven-centos7:latest

MAINTAINER Andrew Lee Rubinger (https://github.com/ALRubinger)

USER root

# Install asciidoctor
RUN yum install -y rubygems && \
    gem install asciidoctor && \
    yum clean all

USER 1001
