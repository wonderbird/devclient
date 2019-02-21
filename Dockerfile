# A dockerized ssh server giving access to a customized development environment
#
# To run this container, please specify the AUTHORIZED_KEYS environment variable
# on the command line. The docker-entrypoint.sh script will replace the file
# /home/git/.ssh/authorized_keys with the contents of this environment variable.
#
# Example:
# $ docker run -it --rm --name dev -v /path/to/home:/home/john --env AUTHORIZED_KEYS=<some_keys> -p 8022:22 devclient
#
# If you would like to run the container and connect a shell to it, then you
# can simply pass "/bin/bash" to the docker command line. This will instruct
# docker-entrypoint.sh to run the "/bin/bash" command instead of /usr/bin/sshd.
#
# Example:
# $ docker run -it --rm --name dev devclient /bin/bash
#
FROM ubuntu:latest

LABEL maintainer="Stefan.Boos@gmx.de"

ENV AUTHORIZED_KEYS # Please set the environment variable AUTHORIZED_KEYS when running the container.

EXPOSE 22/tcp

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y apt-utils \
       	       	       	  git \
    	    	          openssh-server

#####
# Set up privilege separation directory for sshd
####
RUN mkdir /run/sshd \
    && chmod 0755 /run/sshd \
#
#####
# Set up the john user and the associated group
#
# docker-entrypoint.sh will configure the account and sshd such that the
# user can only log in with a key.
#####
#
    && addgroup john \
    && adduser --disabled-password --shell /bin/bash --ingroup john --gecos 'The local user' --home /home/john john

#####
# Let john's home directory be mounted into the container and ensure john can access it.
#####
VOLUME ["/home/john"]

#####
# Setup and run the docker-entrypoint.sh script
#####
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod u+x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["devclient"]
