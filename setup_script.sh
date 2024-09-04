#!/bin/bash

set -x

# Check if the argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 {import|startup|shutdown}"
  exit 1
fi

# Define the OVA folder for import
OVA_FOLDER="OVA"

# Get the username for VirtualBox VMs
if [ "$SUDO_USER" ]; then
  USERNAME=$SUDO_USER
else
  USERNAME=$(whoami)
fi

# Function to handle importing .ova files
import_ova() {
  # Loop through all .ova files in the folder
  for ova_file in "$OVA_FOLDER"/*.ova; do
      if [ -f "$ova_file" ]; then
          echo "Importing $ova_file ..."
          VBoxManage import "$ova_file"
          echo "$ova_file has been imported successfully."
      else
          echo "No .ova files found in $OVA_FOLDER"
          exit 1
      fi
  done
}


startup_vms() {
    # Choose External Interface for interaction

    # List all physical network interfaces (excluding loopback and virtual interfaces)
    interfaces=$(ls /sys/class/net | grep -v lo)

    # Convert interfaces into an array
    interface_list=($(echo "$interfaces"))

    # Check if there are no interfaces
    if [ ${#interface_list[@]} -eq 0 ]; then
        echo "No physical network interfaces found."
        exit 1
    fi

    # Display the menu
    echo "Select a network interface:"
    for i in "${!interface_list[@]}"; do
        echo "$((i+1)). ${interface_list[$i]}"
    done

    # Read user choice
    read -p "Enter the number of the interface (1-${#interface_list[@]}): " choice

    # Validate user input
    if [[ "$choice" -ge 1 && "$choice" -le ${#interface_list[@]} ]]; then
        EXTERNAL_INTERFACE=${interface_list[$((choice-1))]}
        echo "You selected interface: $EXTERNAL_INTERFACE"
    else
        echo "Invalid selection. Exiting."
        exit 1
    fi



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
    sudo -u $USERNAME VBoxManage controlvm "kali-linux-2024.2-virtualbox-amd64" nic2 bridged $EXTERNAL_INTERFACE
    sudo -u $USERNAME VBoxManage controlvm "pfSense" nic1 bridged dmz3
    sudo -u $USERNAME VBoxManage controlvm "ChemicalPlant" nic2 bridged m1
    sudo -u $USERNAME VBoxManage controlvm "plc_2" nic1 bridged m2
    sudo -u $USERNAME VBoxManage controlvm "pfSense" nic2 bridged m4
    sudo -u $USERNAME VBoxManage controlvm "Wazuh-OTSec" nic1 bridged dmz4
    sudo -u $USERNAME VBoxManage controlvm "Wazuh-OTSec" nic2 bridged $EXTERNAL_INTERFACE
    sudo -u $USERNAME VBoxManage controlvm "Wazuh-OTSec" nic3 bridged dmzspan

}

# Function to handle VM shutdown
shutdown_vms() {
  sudo -u $USERNAME VBoxManage controlvm "pfSense" acpipowerbutton
  sudo -u $USERNAME VBoxManage controlvm "ChemicalPlant" acpipowerbutton
  sudo -u $USERNAME VBoxManage controlvm "plc_2" acpipowerbutton
  sudo -u $USERNAME VBoxManage controlvm "ScadaBR" acpipowerbutton
  sudo -u $USERNAME VBoxManage controlvm "kali-linux-2024.2-virtualbox-amd64" acpipowerbutton
  sudo -u $USERNAME VBoxManage controlvm "Wazuh-OTSec" acpipowerbutton
}

# Main logic to call the correct function based on input
case "$1" in
  import)
    import_ova
    ;;
  startup)
    startup_vms
    ;;
  shutdown)
    shutdown_vms
    ;;
  *)
    echo "Usage: $0 {import|startup|shutdown}"
    exit 1
    ;;
esac


