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

# override stupid apt defaults
cat << EOF > $target/etc/apt/apt.conf
APT::Get::Install-Recommends "false";
APT::Get::Install-Suggests "false";
EOF
inside apt update
inside apt install git golang postgresql curl make systemd sudo nodejs npm
inside passwd root

# mattermost-server setup
inside git clone --depth=1 https://github.com/mattermost/mattermost-server /root/mattermost-server
inside bash -c 'cd /root/mattermost-server && bash scripts/download_mmctl_release.sh'
inside cp /root/mattermost-server/build/docker/postgres.conf /etc/postgresql/14/main/postgres.conf
inside chown postgres:postgres /etc/postgresql/14/main/postgres.conf
cat << EOF | inside bash
	echo "CREATE USER $PG_NAME WITH PASSWORD '$PG_PASSWORD';" | sudo -u postgres psql
	echo "CREATE DATABASE $PG_DB;" | sudo -u postgres psql
	echo "GRANT ALL PRIVILEGES ON DATABASE $PG_DB TO $PG_NAME;" | sudo -u postgres psql
EOF

# mattermost-webapp setup
inside git clone --depth=1 https://github.com/mattermost/mattermost-webapp /root/mattermost-webapp
inside bash -c 'cd /root/mattermost-webapp && make test'

# mattermost-desktop setup
