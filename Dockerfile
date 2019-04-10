FROM ubuntu:18.04

LABEL maintainer="ChenJian"

# Get Vapor repo including Swift
RUN apt-get -q update;
RUN apt-get -q install -y wget software-properties-common apt-transport-https;
RUN wget -q https://repo.vapor.codes/apt/keyring.gpg -O- | apt-key add -;
RUN echo "deb https://repo.vapor.codes/apt bionic main" | tee /etc/apt/sources.list.d/vapor.list;

# Installing Swift & Vapor
RUN apt-get update && \
    apt-get -y install libcurl4-openssl-dev swift vapor;

WORKDIR /vapor
COPY . /vapor

RUN ["vapor", "--help"];
RUN vapor build;
RUN vapor run --hostname=0.0.0.0 --port=80;
