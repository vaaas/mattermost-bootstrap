#!/bin/sh
target=mattermost
version=sid
mkdir $target

inside() {
	chroot $target "$@"
}

PG_NAME=mmuser
PG_PASSWORD=mostest
PG_DB=mattermost_test

# basic setup
debootstrap --variant=minbase $version $target
inside apt update
inside apt install git golang postgresql curl make systemd sudo
inside passwd root

# mattermost-server setup
inside git clone --depth=1 https://github.com/mattermost/mattermost-server /root/mattermost-server
inside bash -c 'cd /root/mattermost-server && bash scripts/download_mmctl_release.sh'
inside cp /root/mattermost-server/build/docker/postgres.conf /etc/postgres/postgres.conf
cat << EOF | inside bash
	echo "CREATE USER $PG_NAME WITH PASSWORD '$PG_PASSWORD';" | sudo -u postgres psql
	echo "CREATE DATABASE $PG_DB;" | sudo -u postgres psql
	echo "GRANT ALL PRIVILEGES ON DATABASE $PG_DB TO $PG_NAME;" | sudo -u postgres psql"
EOF

# mattermost-webapp setup
inside git clone --depth=1 https://github.com/mattermost/mattermost-webapp /root/mattermost-webapp