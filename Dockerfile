# FROM resin/rpi-raspbian
FROM debian

RUN apt update && apt install sudo

RUN adduser --disabled-password --gecos '' -u 1001 pi && \
    adduser pi sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER pi

WORKDIR /home/pi

ADD install.sh install.sh

CMD /home/pi/install.sh