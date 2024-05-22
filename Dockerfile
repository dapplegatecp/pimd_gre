FROM alpine:edge
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk upgrade --no-cache && apk add --no-cache pimd iproute2

COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# CMD ["pimd", "-n", "-f", "/etc/pimd.conf", "-d", "all", "-l", "debug", "--disable-vifs"]
CMD ["pimd", "-n", "-f", "/etc/pimd.conf", "-d", "all", "-l", "debug"]