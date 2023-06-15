#!/usr/bin/env zsh

# Check for network connection
has_net_connection() {
  # Check for network connection
  if ! ping -c 1 archlinux.org &> /dev/null; then
    return 1
  fi
}

# Check for root
is_root() {
  # Check for root
  if [ "$EUID" -ne 0 ]; then
    return 1
  fi
}

# Check for `dialog`
has_dialog() {
  # Check for `dialog`
  if ! command -v dialog &> /dev/null; then
    return 1
  fi
}

# Get all partitions on a disk
get_partitions() {
  lsblk -lno NAME $1 | grep -v $1 | sed '1d'
}

# Confirm partition exists on a disk
confirm_partition_exists() {
  if [ ! -e "$1" ]; then
    return 1
  fi
}


# A map of country acronyms to country names
declare -A country_map
country_map[AR]="Argentina"
country_map[AU]="Australia"
country_map[AT]="Austria"
country_map[AZ]="Azerbaijan"
country_map[BD]="Bangladesh"
country_map[BY]="Belarus"
country_map[BE]="Belgium"
country_map[BA]="Bosnia_and_Herzegovina"
country_map[BR]="Brazil"
country_map[BG]="Bulgaria"
country_map[KH]="Cambodia"
country_map[CA]="Canada"
country_map[CL]="Chile"
country_map[CN]="China"
country_map[CO]="Colombia"
country_map[HR]="Croatia"
country_map[CZ]="Czechia"
country_map[DK]="Denmark"
country_map[EC]="Ecuador"
country_map[EE]="Estonia"
country_map[FI]="Finland"
country_map[FR]="France"
country_map[GE]="Georgia"
country_map[DE]="Germany"
country_map[GR]="Greece"
country_map[HK]="Hong_Kong"
country_map[HU]="Hungary"
country_map[IS]="Iceland"
country_map[IN]="India"
country_map[ID]="Indonesia"
country_map[IR]="Iran"
country_map[IE]="Ireland"
country_map[IL]="Israel"
country_map[IT]="Italy"
country_map[JP]="Japan"
country_map[KZ]="Kazakhstan"
country_map[KE]="Kenya"
country_map[LV]="Latvia"
country_map[LT]="Lithuania"
country_map[LU]="Luxembourg"
country_map[MU]="Mauritius"
country_map[MX]="Mexico"
country_map[MD]="Moldova"
country_map[MC]="Monaco"
country_map[NL]="Netherlands"
country_map[NC]="New_Caledonia"
country_map[NZ]="New_Zealand"
country_map[MK]="North_Macedonia"
country_map[NO]="Norway"
country_map[PY]="Paraguay"
country_map[PL]="Poland"
country_map[PT]="Portugal"
country_map[RO]="Romania"
country_map[RU]="Russia"
country_map[RE]="Réunion"
country_map[RS]="Serbia"
country_map[SG]="Singapore"
country_map[SK]="Slovakia"
country_map[SI]="Slovenia"
country_map[ZA]="South_Africa"
country_map[KR]="South_Korea"
country_map[ES]="Spain"
country_map[SE]="Sweden"
country_map[CH]="Switzerland"
country_map[TW]="Taiwan"
country_map[TH]="Thailand"
country_map[TR]="Turkey"
country_map[UA]="Ukraine"
country_map[GB]="United_Kingdom"
country_map[US]="United_States"
country_map[UZ]="Uzbekistan"
country_map[VN]="Vietnam"

dialog_friendly_countries() {
  # `dialog --checklist` expects a list of options like so:
  #   <tag> <item> <status>
  # where `tag` is a unique identifier, `item` is the text to display, and
  # `status` is either "on" or "off" to indicate whether the item is selected.

  # Create a list of countries in the format expected by `dialog`
  local country_list=()
  for country in "${(@k)country_map}"; do
    country_list+=("$country" "${country_map[$country]}" "off")
  done

  # Return the list
  echo "${country_list[@]}"
}

dialog_friendly_timezones() {
  # `dialog --menu` expects a list of options like so:
  #   <tag> <item>
  # where `tag` is a unique identifier, `item` is the text to display

  local timezones=($(find /usr/share/zoneinfo -type f))
  local timezone_list=()
  local index=1
  for timezone in $timezones; do
    timezone_list+=("$timezone" "$index")
    index=$((index + 1))
  done

  echo "${timezone_list[@]}"
}

dialog_friendly_locales() {
  # `dialog --menu` expects a list of options like so:
  #   <tag> <item>
  # where `tag` is a unique identifier, `item` is the text to display
  # skip first 17 lines in locale.gen

  local locales=($(cat /etc/locale.gen | grep -v "#" | sed '1,17d' | sed 's/#//g'))
  local locale_list=()
  local index=1
  for locale in $locales; do
    locale_list+=("$locale" "$index")
    index=$((index + 1))
  done

  echo "${locale_list[@]}"
}

dialog_friendly_disks() {
  # `dialog --menu` expects a list of options like so:
  #   <tag> <item>
  # where `tag` is a unique identifier, `item` is the text to display

  local disks=($(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | sort -k 1 | sed 's/ /./g'))
  local disks_list=()
  local index=1
  for disk in $disks; do
    disks_list+=("$disk" "$index")
    index=$((index + 1))
  done

  echo "${disks_list[@]}"
}
