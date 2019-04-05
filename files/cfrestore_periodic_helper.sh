#!/bin/dash

# Originally, part of cfdb restore logic

set -a

user=$1
backup_root_dir=$2
service_name=$3
script=$4

if [ -z "$user" -o -z "$backup_root_dir" -o -z "$service_name" ]; then
    echo "Usage: $0 <user> <backup_root_dir> <service_name>"
    echo "Inner script must be passed to STDIN"
    exit 1
fi

# Make sure to run under instance user
if test "$(/usr/bin/id -u)" != 0; then
    echo "Error: this script must run under root"
    exit 1
fi

set -e

sub_dir="$(cat ${backup_root_dir}/last_backup)"
backup_dir="${backup_root_dir}/${sub_dir}"


echo
echo "Last backup location: $backup_dir"
echo
echo "NOTE: if needed, you must ensure the cluster is in a clean state by yourself!"
echo

if ! test -d "$backup_dir"; then
    echo "Last backup is not a directory"
    exit 1
fi

confirm1='Yes, I am sure'
confirm2='Yes, I am REALLY sure'

echo
echo "Are you sure you want to restore the last backup?"
read -p "Print '$confirm1': " check
test "$check" = "$confirm1" || exit 1

echo
echo "Are you really, really sure?"
read -p "Print '$confirm2': " check
test "$check" = "$confirm2" || exit 1

echo
echo "------------------------------------"
echo "Starting restore from ${backup_dir}!"
echo "------------------------------------"
echo

# Execute inner script
if ! /bin/dash -ex -c "$script"; then
    echo "----------------"
    echo " !!! FAILED !!!"
    echo "----------------"
    exit 1
fi


# make sure we do not make incremental backups with invalid base
# NOTE: not critical for rdiff, but make it consistent
/bin/mv "${backup_dir}" "${backup_dir}.restored_at_$(/bin/date '+%Y%m%d_%H%M%S')"

set +ex
echo
echo "---------"
echo "All done!"
echo "---------"
