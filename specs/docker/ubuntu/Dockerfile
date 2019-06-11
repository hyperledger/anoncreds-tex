FROM ubuntu:18.04

LABEL maintainer="Michael Lodder <redmike7@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEED=true

RUN echo "tzdata tzdata/Areas select US" | debconf-set-selections \
    && echo "tzdata tzdata/Zones/US select Mountain" | debconf-set-selections \
    && apt update 2>&1 > /dev/null \
    && apt install -qq -y texlive-latex-extra texlive-extra-utils texlive-science 2>&1 > /dev/null
