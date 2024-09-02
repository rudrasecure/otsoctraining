#!/bin/bash

set -x
#Set these
VBOXNETDMZ=vboxnet2
VBOXNETMZ=vboxnet3
USERNAME=apocalypse0 #User who is running the VirtualBox VMs

ip link del dmz1
ip link del dmz2
ip link del dmz3
ip link del dmz4
ip link del dmzspan

ip link del m1
ip link del m2
ip link del m3
ip link del m4
ip link del m5
ip link del mspan

ovs-vsctl del-br dmzbr
ovs-vsctl del-br mzbr

ovs-vsctl add-br dmzbr
ovs-vsctl add-br mzbr
ovs-vsctl -- --id=@m create mirror name=dmzspanmirror -- add bridge dmzbr mirrors @m
ovs-vsctl -- --id=@m create mirror name=mzpspanmirror -- add bridge mzbr mirrors @m

#DMZ Interfaces 
ip tuntap add dmz1 mode tap #ScadaBr
ip tuntap add dmz2 mode tap #Kali Box
ip tuntap add dmz3 mode tap #PF Sense
ip tuntap add dmz4 mode tap #Active Security
ip tuntap add dmzspan mode tap #SPAN Port 

ovs-vsctl add-port dmzbr dmz1
ovs-vsctl add-port dmzbr dmz2
ovs-vsctl add-port dmzbr dmz3
ovs-vsctl add-port dmzbr dmz4
ovs-vsctl add-port dmzbr dmzspan
#ovs-vsctl add-port dmzbr $VBOXNETDMZ
ovs-vsctl -- --id=@p get port dmzspan -- set mirror dmzspanmirror select_all=true output-port=@p

ip link set dmz1 up
ip link set dmz2 up
ip link set dmz3 up
ip link set dmz4 up
ip link set dmzspan up
ip link set dmzspan promisc on


#MZ Interfaces
ip tuntap add m1 mode tap   #Chemical Plant Process
ip tuntap add m2 mode tap   #PLC  
ip tuntap add m3 mode tap   #WorkStation
ip tuntap add m4 mode tap   #PFSense
ip tuntap add m5 mode tap   #Active Security
ip tuntap add mspan mode tap    #SPAN

ovs-vsctl add-port mzbr m1
ovs-vsctl add-port mzbr m2
ovs-vsctl add-port mzbr m3
ovs-vsctl add-port mzbr m4
ovs-vsctl add-port mzbr m5
#ovs-vsctl add-port mzbr $VBOXNETMZ
ovs-vsctl add-port mzbr mspan

ovs-vsctl -- --id=@p get port mspan -- set mirror mzpspanmirror select_all=true output-port=@p


ip link set m1 up
ip link set m2 up
ip link set m3 up
ip link set m4 up
ip link set m5 up
ip link set mspan up
ip link set mspan promisc on


sudo -u $USERNAME VBoxManage startvm "pfSense"
sudo -u $USERNAME VBoxManage startvm "ChemicalPlant"
sudo -u $USERNAME VBoxManage startvm "plc_2"
sudo -u $USERNAME VBoxManage startvm "ScadaBR"
sudo -u $USERNAME VBoxManage startvm "kali-linux-2024.2-virtualbox-amd64"
sudo -u $USERNAME VBoxManage startvm "Wazuh-OTSec"

sudo -u $USERNAME VBoxManage controlvm "ScadaBR" nic1 bridged dmz1
sudo -u $USERNAME VBoxManage controlvm "kali-linux-2024.2-virtualbox-amd64" nic1 bridged dmz2
sudo -u $USERNAME VBoxManage controlvm "pfSense" nic1 bridged dmz3
sudo -u $USERNAME VBoxManage controlvm "ChemicalPlant" nic2 bridged m1
sudo -u $USERNAME VBoxManage controlvm "plc_2" nic1 bridged m2
sudo -u $USERNAME VBoxManage controlvm "pfSense" nic2 bridged m4




