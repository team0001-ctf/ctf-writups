FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y xinetd

RUN useradd -m deck_of_vulns

RUN mkdir /home/deck_of_vulns/usr
RUN cp -R /lib* /home/deck_of_vulns
RUN cp -R /usr/lib* /home/deck_of_vulns/usr

RUN mkdir /home/deck_of_vulns/bin && \
    cp /bin/* /home/deck_of_vulns/bin

RUN mkdir /home/deck_of_vulns/dev && \
    mknod /home/deck_of_vulns/dev/null c 1 3 && \
    mknod /home/deck_of_vulns/dev/zero c 1 5 && \
    mknod /home/deck_of_vulns/dev/random c 1 8 && \
    mknod /home/deck_of_vulns/dev/urandom c 1 9 && \
    chmod 666 /home/deck_of_vulns/dev/*

COPY ./challenge.xinetd /etc/xinetd.d/challenge
COPY ./start.sh /start.sh
RUN echo "Quit Spamming..." > /etc/banner_fail

RUN chmod +x /start.sh

COPY ./bin/ /home/deck_of_vulns/
RUN chown -R root:deck_of_vulns /home/deck_of_vulns && \
    chmod -R 750 /home/deck_of_vulns && \
    chmod 740 /home/deck_of_vulns/flag.txt

CMD ["/start.sh"]

EXPOSE 1337