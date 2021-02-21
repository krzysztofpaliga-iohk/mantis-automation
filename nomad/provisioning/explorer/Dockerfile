FROM openjdk:8-jdk-slim-buster

ARG USER_HOME="/root"
ARG SCRIPTS="scripts"
ARG STARTUP_SCRIPT="startup.sh"
ARG MANTIS_EXPLORER="mantis-explorer"
ARG EXPLORER_GIT_URL="https://github.com/input-output-hk/${MANTIS_EXPLORER}.git"

RUN apt-get update && apt-get install -y curl gnupg2 git wget
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get install -y yarn
SHELL ["/bin/bash", "-c"]

WORKDIR ${USER_HOME}
ADD ${SCRIPTS}/${STARTUP_SCRIPT} ${STARTUP_SCRIPT}
RUN chmod +x ${STARTUP_SCRIPT}
RUN git clone ${EXPLORER_GIT_URL}

WORKDIR ${USER_HOME}/${MANTIS_EXPLORER}
RUN yarn install

