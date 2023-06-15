#!/usr/bin/env zsh

source ./utils.sh

is_root || (echo "You must be root to run this script." && exit 1)

echo "Checking for network connection..."
has_net_connection || (echo "You must have a network connection to run this script." && exit 1)

echo "Checking for \`dialog\`..."
has_dialog || (echo "You must have \`dialog\` installed to run this script." && exit 1)

#############################
#     ____  _      __       
#    / __ \(_)____/ /_______
#   / / / / / ___/ //_/ ___/
#  / /_/ / (__  ) ,< (__  ) 
# /_____/_/____/_/|_/____/ 
#
#############################

# Get the list of disks sorted by name (sda, sdb, sdc, etc.)
disks=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | sort -k 1)

# Present the disks to the user
dialog --title "Select disk" --menu "Select the disk to install Arch Linux on\n\nDisk size: $disk_size" 15 55 4 $(echo $(dialog_friendly_disks)) 2> disk

# Get the disk from the user
disk=$(cat disk | sed 's/\./ /g' | awk '{print $1}')

# Present a partitioning menu to the user
dialog --title "Partitioning" --menu "Select the partitioning scheme" 15 55 4 \
  1 "Automatic (Recommended)" \
  2 "Manual" 2> partitioning

# Get the partitioning scheme from the user
partitioning=$(cat partitioning)

if [ "$partitioning" = "1" ]; then
  # Use the entire disk
  # Create a 512M EFI partition (FAT32)
  # Create a 30G root partition (ext4)
  # Create a 4G swap partition (swap)
  # Create a home partition with the remaining space (ext4)

  # Confirm the partitioning scheme with the user
  dialog --title "Confirm partitioning" --yesno "Are you sure you want to use the following partitioning scheme?\n\nDisk: $disk\n\nEFI: 512M\nRoot: 30G\nSwap: 4G\nHome: Remaining space" 15 55

  # Get the user's confirmation
  confirmed=$?

  # If the user confirmed the partitioning scheme
  if [ "$confirmed" = "0" ]; then
    # Partition the disk
    parted -s $disk \
      mklabel gpt \
      mkpart ESP fat32 1MiB 513MiB \
      set 1 boot on \
      mkpart primary ext4 513MiB 31.5GiB \
      mkpart primary linux-swap 31.5GiB 35.5GiB \
      mkpart primary ext4 35.5GiB 100%

    # Format the partitions
    mkfs.fat -F32 ${disk}1
    mkfs.ext4 ${disk}2
    mkswap ${disk}3
    mkfs.ext4 ${disk}4

    # Mount the partitions
    mount ${disk}2 /mnt
    mkdir /mnt/boot
    mount ${disk}1 /mnt/boot
    swapon ${disk}3
    mkdir /mnt/home
    mount ${disk}4 /mnt/home
  else
    # The user did not confirm the partitioning scheme
    # Exit the script
    exit 1
  fi

elif [ "$partitioning" = "2" ]; then
  # use cfdisk to partition the disk
  cfdisk $disk || exit 1

  # Ask a few basic questions
  # What is the boot partition?
  # What is the root partition?
  # Is there a swap partition, if so what?
  # Is there a home partition, if so what?
  
  dialog --title "Partition information" --msgbox "You will now be asked a few questions about your partitions.\n\nPress OK to continue." 15 55

  # Get the boot partition
  dialog --title "Boot partition" --inputbox "What is the boot partition?" 15 55 2> boot_partition
  confirm_partition_exists $boot_partition || (echo "The boot partition does not exist." && exit 1)

  # Get the root partition
  dialog --title "Root partition" --inputbox "What is the root partition?" 15 55 2> root_partition
  confirm_partition_exists $root_partition || (echo "The root partition does not exist." && exit 1)

  # Get the swap partition
  swap_partition=""
  dialog --title "Swap partition" --yesno "Is there a swap partition?" 15 55

  if [ $? -eq 0 ]; then
    # Get the swap partition
    dialog --title "Swap partition" --inputbox "What is the separate swap partition?" 15 55 2> swap_partition

    confirm_partition_exists $swap_partition || (echo "The swap partition does not exist." && exit 1)
  fi

  # Get the home partition
  home_partition=""
  dialog --title "Home partition" --yesno "Is there a separare home partition?" 15 55

  if [ $? -eq 0 ]; then
    # Get the home partition
    dialog --title "Home partition" --inputbox "What is the home partition?" 15 55 2> home_partition

    confirm_partition_exists $home_partition || (echo "The home partition does not exist." && exit 1)
  fi

  # Confirm the partitioning scheme with the user
  dialog --title "Confirm partitioning" --yesno "Are you sure you want to use the following partitioning scheme?\n\nDisk: $disk\n\nBoot: $boot_partition\nRoot: $root_partition\nSwap: $swap_partition\nHome: $home_partition" 15 55

  # Get the user's confirmation
  if [ $? -eq 0 ]; then
    # Format the partitions
    mkfs.ext4 $root_partition
    mkfs.fat -F32 $boot_partition

    if [ ! -z "$swap_partition" ]; then
      mkswap $swap_partition
    fi

    if [ ! -z "$home_partition" ]; then
      mkfs.ext4 $home_partition
    fi

    # Mount the partitions
    mount $root_partition /mnt
    mkdir /mnt/boot
    mount $boot_partition /mnt/boot

    if [ ! -z "$swap_partition" ]; then
      swapon $swap_partition
    fi

    if [ ! -z "$home_partition" ]; then
      mkdir /mnt/home
      mount $home_partition /mnt/home
    fi
  else
    exit 1
  fi
fi

######################################################
#     ____             __               _            
#    / __ \____ ______/ /______ _____ _(_)___  ____ _
#   / /_/ / __ `/ ___/ //_/ __ `/ __ `/ / __ \/ __ `/
#  / ____/ /_/ / /__/ ,< / /_/ / /_/ / / / / / /_/ / 
# /_/    \__,_/\___/_/|_|\__,_/\__, /_/_/ /_/\__, /  
#                             /____/        /____/   
#
######################################################

dialog --title "Mirrorlist" --msgbox "You will now be asked to select a mirrorlist.\n\nPress OK to continue." 15 55

# Get list of countries
dialog --title "Mirrorlist" --checklist "Select a mirrorlist" 15 55 4 $(echo $(dialog_friendly_countries)) 2> country

# Organize the list of countries (reflector requires a list of countries separated by commas)
countries=$(cat country | tr '\n' ',' | sed 's/,$//')

# Get the user's confirmation
dialog --title "Mirrorlist" --yesno "Are you sure you want to use the following countries?\n\n$countries" 15 55

if [ $? -eq 0 ]; then
  # Get the mirrorlist
  reflector --verbose --country $countries --sort rate --save /etc/pacman.d/mirrorlist
else
  # Let reflector choose the mirrors
  reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
fi

#####################################################
#     ____              __       __                 
#    / __ )____  ____  / /______/ /__________ _____ 
#   / __  / __ \/ __ \/ __/ ___/ __/ ___/ __ `/ __ \
#  / /_/ / /_/ / /_/ / /_(__  ) /_/ /  / /_/ / /_/ /
# /_____/\____/\____/\__/____/\__/_/   \__,_/ .___/ 
#                                          /_/      
#####################################################

dialog --title "Base packages" --msgbox "You will now be asked to select the base packages.\n\nPress OK to continue." 15 55

# Get the base packages
dialog --title "Base packages" --checklist "Select the base packages" 15 55 4 \
  base "The base system" on \
  base-devel "The base development tools" on \
  linux-firmware "The linux firmware" on \
  linux-headers "The linux headers" on 2> base_packages

base_packages=$(cat base_packages)

# Get the kernel
dialog --title "Kernel" --radiolist "Select the kernel" 15 55 4 \
  linux "Stable Linux" on \
  linux-hardened "Hardened Linux" off \
  linux-lts "LTS (Long-Term Support) Linux" off \
  linux-rt "Real-Time Linux" off \
  linux-rt-lts "LTS (Long-Term Support) Real-Time Linux" off \
  linux-zen "Zen Linux" off 2> kernel

kernel=$(cat kernel)

# Ask the user if they want to install additional packages
additional_packages=""
dialog --title "Additional packages" --yesno "Would you like to install additional packages?" 15 55

if [ $? -eq 0 ]; then
  # Get the additional packages
  dialog --title "Additional packages" --inputbox "Enter the additional packages you would like to install. (space-separated)" 15 55 2> additional_packages

  additional_packages=$(cat additional_packages)  
fi

# Get the user's confirmation
dialog --title "All Packages" --yesno "Are you sure you want to install the following packages?\n\n$base_packages\n\nKernel: $kernel\n\nAdditional: $additional_packages" 15 55

# Get the user's confirmation on the additional packages
if [ $? -eq 0 ]; then
  # Install the base packages, kernel, and additional packages
  # split by space so it's not parsed as a single string
  pacstrap /mnt $(echo $base_packages) $(echo $kernel) $(echo $additional_packages)
else
  exit 1
fi

########################################
#     _______             ___          
#    / ____(_)___  ____ _/ (_)___  ___ 
#   / /_  / / __ \/ __ `/ / /_  / / _ \
#  / __/ / / / / / /_/ / / / / /_/  __/
# /_/   /_/_/ /_/\__,_/_/_/ /___/\___/ 
#
########################################

genfstab -U /mnt >> /mnt/etc/fstab

# Copy the script's parent directory to the new system
cp -r $(dirname $0) /mnt/tmp/jumpstart

touch /mnt/tmp/jumpstart/.bootstrapped

echo "You can now chroot into the new system and run the configure script from /tmp/jumpstart/configure.sh"
echo "Use the following command to chroot into the new system:"
echo "arch-chroot /mnt"
