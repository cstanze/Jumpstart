# Check if the `.bootstrapped` file is present.
if [ ! -f .bootstrapped ]; then
  # If the file is not present, then run the bootstrap script.
  echo "You must bootstrap the system before running this script."
fi

source ./utils.sh

is_root || (echo "You must be root to run this script." && exit 1)

echo "Checking for network connection..."
has_net_connection || (echo "You must have a network connection to run this script." && exit 1)

echo "Checking for \`dialog\`..."
has_dialog || (echo "You must have \`dialog\` installed to run this script." && exit 1)

##############################################################
#     __                     ___             __  _           
#    / /   ____  _________ _/ (_)___  ____ _/ /_(_)___  ____ 
#   / /   / __ \/ ___/ __ `/ / /_  / / __ `/ __/ / __ \/ __ \
#  / /___/ /_/ / /__/ /_/ / / / / /_/ /_/ / /_/ / /_/ / / / /
# /_____/\____/\___/\__,_/_/_/ /___/\__,_/\__/_/\____/_/ /_/ 
#
##############################################################

# present the timezones to the user
dialog --title "Localization" --menu "Select your timezone" 15 55 4 $(echo $(dialog_friendly_timezones)) 2> timezone
timezone=$(cat timezone)

ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

# present the locales to the user
dialog --title "Localization" --menu "Select your locale" 15 55 4 $(echo $(dialog_friendly_locales)) 2> locale
locale=$(cat locale)

echo "LANG=$locale" > /etc/locale.conf

###################################################################
#     ____    __           __  _ _____            __  _           
#    /  _/___/ /__  ____  / /_(_) __(_)________ _/ /_(_)___  ____ 
#    / // __  / _ \/ __ \/ __/ / /_/ / ___/ __ `/ __/ / __ \/ __ \
#  _/ // /_/ /  __/ / / / /_/ / __/ / /__/ /_/ / /_/ / /_/ / / / /
# /___/\__,_/\___/_/ /_/\__/_/_/ /_/\___/\__,_/\__/_/\____/_/ /_/ 
#
###################################################################

# get hostname
dialog --title "Hostname" --inputbox "Enter your hostname" 15 55 2> hostname
hostname=$(cat hostname)

echo $hostname > /etc/hostname

# get root password
dialog --title "Root password" --passwordbox "Enter your root password" 15 55 2> root_password
root_password=$(cat root_password)

echo "root:$root_password" | chpasswd

############################
#     ____              __ 
#    / __ )____  ____  / /_
#   / __  / __ \/ __ \/ __/
#  / /_/ / /_/ / /_/ / /_  
# /_____/\____/\____/\__/  
#
############################                        

# install grub and os-prober
pacman -S --noconfirm grub os-prober

# install grub to the disk
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# generate grub config
grub-mkconfig -o /boot/grub/grub.cfg

# clean up the chroot environment
rm -rf /tmp/*
rm -rf root_password
rm -rf hostname
rm -rf locale
rm -rf timezone

# done!
echo "Done! You can now exit the chroot environment and reboot."
