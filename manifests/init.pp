#
# Copyright 2019 (c) Andrey Galkin
#


# Please see README
class cfbackup (
    Enum['s3', 'sftp', 'local']
        $type = 'local',
    String[1]
        $root_dir = '/mnt/backup',
    String[1]
        $timer = 'daily',
    Integer[0]
        $reserve_ram = 64,
) {
    include stdlib
    include cfnetwork
    include cfsystem
    include cfsystem::custombin

    file { $root_dir:
        ensure => directory,
        mode   => '0511',
    }

    $backup_all = "${cfsystem::custombin::bin_dir}/cfbackup_all"
    $upload_all = "${cfsystem::custombin::bin_dir}/cfbackup_upload_all"
    $upload_helper = "${cfsystem::custombin::bin_dir}/cfbackup_upload_helper"
    $restore_helper = "${cfsystem::custombin::bin_dir}/cfbackup_restore_helper"

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

    #---
    ensure_packages(['jq'])

    Package['jq']
    -> file { $backup_all:
        mode    => '0555',
        content => epp('cfbackup/cfbackup_all.sh.epp'),
    }
    -> file { $upload_all:
        mode    => '0555',
        content => epp('cfbackup/cfbackup_upload_all.sh.epp'),
    }
    ->cfsystem_memory_weight { 'cftimer-backupall':
        ensure => present,
        weight => 1,
        min_mb => $reserve_ram,
        max_mb => $reserve_ram,
    }
    -> cfsystem_timer {'cftimer-backupall':
        ensure     => present,
        user       => root,
        root_dir   => $root_dir,
        command    => $backup_all,
        cpu_weight => 1,
        io_weight  => 1,
        calendar   => $timer,
        # memory_weight - not set on purpose
    }

    include "cfbackup::${type}"
}
