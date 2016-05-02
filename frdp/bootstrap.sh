#!/bin/sh

#sudo perl -pi.bak -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
#sudo echo 0 > /selinux/enforce
#sudo systemctl disable firewalld
#sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
#sudo echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list
#sudo apt-get update 
#sudo apt-get install docker.io -y

sudo ufw allow 2375/tcp

# Create partition for ZFS
sudo parted /dev/sdb mklabel msdos
sudo parted /dev/sdb mkpart primary zfs 0 100%

# Create ZFS mount point and pools
sudo mkdir /zroot
sudo zpool create frpool -m /zroot /dev/sdb1
sudo zpool set listsnapshots=on frpool
sudo zfs set compression=on frpool
sudo zfs set dedup=on frpool
sudo zfs create frpool/frdp
#sudo zfs create -o mountpoint=/var/lib/docker frpool/docker
sudo zfs create frpool/docker

# Bootstrap docker for ZFS
sudo echo "DOCKER_OPTS=\" -g /zroot/docker/ --storage-driver=zfs --storage-opt zfs.fsname=frpool/docker\"" >> /etc/default/docker
sudo service docker restart
#sudo docker info
sudo systemctl enable docker

#lxc remote add images images.linuxcontainers.org
lxc config set storage.zfs_pool_name frpool
sudo lxd init --auto --network-address=[::] --network-port=10443 --storage-backend=zfs --storage-pool=frpool --trust-password=Admin123

# Housekeeping
sudo echo "127.0.1.1  mysp.forgerocksp.org gateway.forgerockdemo.com" >> /etc/hosts
sudo groupadd forgerock -g 500
sudo useradd forgerock -m  -s /bin/bash -u 500 -g 500
sudo mkdir /zroot/frdp/forgerock /zroot/frdp/forgerock/ext
sudo chown -R forgerock:forgerock /zroot/frdp/forgerock
sudo ln -s /zroot/frdp/forgerock /opt/forgerock

# Update the forgerock user's bashrc
cd /tmp && sudo wget ftp://ftp.wfoo.net/bashrc --user=frdp@wfoo.net --password=ForgeRock16!
sudo cat /tmp/bashrc >> /home/forgerock/.profile

# Install standalone MySQL instead of packaged one
#cd /opt/forgerock/ext && sudo wget -b ftp://ftp.wfoo.net/mysql-5.6.29-linux-glibc2.5-x86_64.tar.7z --user=frdp@wfoo.net --password=ForgeRock16! -o /tmp/wget.log

# Install the ForgeRock stack using docker
#sudo docker run  -d -v /zroot/frdp/forgerock/dj:/opt/forgerock/opendj/instances/instance1 forgerock/opendj:nightly
