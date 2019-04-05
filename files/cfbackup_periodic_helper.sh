#!/bin/dash

# Originally, part of cfdb backup logic

set -a

user=$1
backup_root_dir=$2
date_method=$3

if [ -z "$user" -o -z "$backup_root_dir" -o -z "$date_method" ]; then
    echo "Usage: $0 <user> <backup_root_dir> <date_method>"
    echo "Inner script must be passed to STDIN"
    exit 1
fi

# Make sure to run under required user
if [ "$(/usr/bin/id -nu)" != "$user" ]; then
    exec /usr/bin/sudo -i -u "$user" $0 "$@"
    # should not reach here
    exit -1
fi

set -e

case $date_method in
    'year') base_date='%Y' ;;
    'quarter') base_date="%Y-Q$(( $(/bin/date +%m) / 4 + 1 ))" ;;
    'month') base_date='%Y-%m' ;;
    'week') base_date='%Y-W%W' ;;
    'day') base_date='%Y-%m-%d' ;;
    'daytime') base_date='%Y-%m-%d_%H%M%S' ;;
    *) echo "Invalid date method: ${date_method}"; exit 1 ;;
esac

sub_dir=$(/bin/date --utc "+${base_date}")
backup_dir="${backup_root_dir}/${sub_dir}"

echo "-----------------------------------"
echo "Starting backup into ${backup_dir}!"
echo "-----------------------------------"

exec 3<${backup_root_dir}/backup.lock

if ! flock -xn 3; then
    echo "Error: failed to get backup lock!"
    exit 1
fi

# Execute inner script
if ! /bin/dash -ex -; then
    echo "----------------"
    echo " !!! FAILED !!!"
    echo "----------------"
    exit 1
fi

# complete
echo $sub_dir > ${backup_root_dir}/last_backup

set +ex
echo "---------"
echo "All done!"
echo "---------"
