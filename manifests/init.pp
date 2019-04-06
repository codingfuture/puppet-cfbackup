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
        $backup_timer = 'hourly',
    String[1]
        $upload_timer = 'daily',
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

    $lock_timeout = 60
    $backup_all = "${cfsystem::custombin::bin_dir}/cfbackup_all"
    $upload_all = "${cfsystem::custombin::bin_dir}/cfbackup_upload_all"
    $download_latest = "${cfsystem::custombin::bin_dir}/cfbackup_download_latest"
    $upload_helper = "${cfsystem::custombin::bin_dir}/cfbackup_upload_helper"
    $download_helper = "${cfsystem::custombin::bin_dir}/cfbackup_download_helper"

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
    -> file { $download_latest:
        mode    => '0555',
        content => epp('cfbackup/cfbackup_download_latest.sh.epp'),
    }
    ->cfsystem_memory_weight { 'cfbackup':
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
        calendar   => $backup_timer,
        # memory_weight - not set on purpose
    }
    -> cfsystem_timer {'cftimer-uploadall':
        ensure     => present,
        user       => root,
        root_dir   => $root_dir,
        command    => $upload_all,
        cpu_weight => 1,
        io_weight  => 1,
        calendar   => $upload_timer,
        # memory_weight - not set on purpose
    }

    include "cfbackup::${type}"
}
