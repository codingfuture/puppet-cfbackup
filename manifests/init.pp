#
# Copyright 2019 (c) Andrey Galkin
#


# Please see README
class cfbackup (
    Enum['s3', 'sftp', 'local']
        $type = 'local',
    String[1]
        $root_dir = '/mnt/backup',
    Hash
        $timer = {},
) {
    include stdlib
    include cfnetwork
    include cfsystem
    include cfsystem::custombin

    file { $root_dir:
        ensure => directory,
        mode   => '0511',
    }

    $periodic_helper = "${cfsystem::custombin::bin_dir}/cfbackup_periodic_helper.sh"
    $periodic_restore_helper = "${cfsystem::custombin::bin_dir}/cfrestore_periodic_helper.sh"

    file { $periodic_helper:
        mode    => '0555',
        content => file('cfbackup/cfbackup_periodic_helper.sh'),
    }
    file { $periodic_restore_helper:
        mode    => '0555',
        content => file('cfbackup/cfrestore_periodic_helper.sh'),
    }

    include "cfbackup::${type}"
}
