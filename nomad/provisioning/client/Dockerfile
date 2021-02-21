FROM openjdk:8-jdk-slim-buster

ARG MANTIS="mantis"
ARG USER_HOME="/root"
ARG MANTIS_DIST="mantis-dist"
ARG MANTIS_GIT_URL="https://github.com/input-output-hk/mantis.git"

RUN apt-get update
RUN apt-get install -y apt-utils net-tools psmisc perl git g++ make cmake build-essential vim mc curl tar zip unzip bash procps expect htop lsof libc6-dev libboost-all-dev jq netcat
RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
RUN apt-get update
RUN apt-get install -y sbt
SHELL ["/bin/bash", "-c"]

ENV JAVA_TOOL_OPTIONS '-Dfile.encoding=UTF8 -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false'

WORKDIR ${USER_HOME}
ADD ${MANTIS_DIST}/ ${MANTIS_DIST}/
RUN git clone ${MANTIS_GIT_URL}

WORKDIR ${MANTIS}
RUN git submodule update --recursive --init

WORKDIR ${USER_HOME}/${MANTIS_DIST}

ENTRYPOINT ["./bin/startup.sh"]
