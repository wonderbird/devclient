#!/bin/bash
#
# Entrypoint for the devclient docker container
#
# This script will create the /root/.ssh/authorized_keys file and copy the
# value of the $AUHTORIZED_KEYS environment variable into it. Then it will run
# either /usr/bin/top or the command provided as arguments to this script.
#
# Adopted from https://github.com/docker-library/postgres/blob/master/docker-entrypoint.sh
set -eufo pipefail

# Configure OpenSSH
# - generate host keys
# - disallow password based logins - the john user may only use key-based auth
# - allow the users matching AUTHORIZED_KEYS to log in as user "john"
ssh-keygen -A

# Toggle the PasswordAuthentication flag from "yes" to "no"
sed -i '/#PasswordAuthentication/ s/yes/no/' /etc/ssh/sshd_config

# Uncomment the PasswordAuthentication flag
sed -i '/#PasswordAuthentication no/ s/#//' /etc/ssh/sshd_config

# Configure SSH access for user john
mkdir -p /home/john/.ssh
touch /home/john/.ssh/authorized_keys
chown -R john:john /home/john/.ssh
chmod -R 700 /home/john/.ssh
chmod 600 /home/john/.ssh/authorized_keys

echo "$AUTHORIZED_KEYS" | sed 's/\\n/\n/g' >/home/john/.ssh/authorized_keys

# Enable the john user by configuring a random 64 byte password
export PASSWD="$(LC_ALL=C tr -dc 'A-Za-z0-9!#$%&()*+,-./:;<=>?@[]_{|}' </dev/urandom | head -c 64)"
echo -e "$PASSWD\n$PASSWD" | passwd john
export PASSWD=

if [ "$1" = "devclient" ]; then
    /usr/sbin/sshd -D -e
else
    exec "$@"
fi
