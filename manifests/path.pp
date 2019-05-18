#
# Copyright 2019 (c) Andrey Galkin
#

define cfbackup::path(
    String[1]
        $namespace,
    String[1]
        $id,
    Enum['files', 'periodic_dump']
        $type,
    Boolean
        $compress = true,
    Optional[String[1]]
        $prepare = undef,
) {
    include cfbackup

    $path = $title

    if $type == 'files' {
        if $prepare {
            fail("'files' backup type does not support custom prepare handler!")
        }

        ensure_packages(['rdiff-backup'])

        $backup_dir = "${cfbackup::root_dir}/${namespace}/${id}"
        $backup_cmd = "${::cfsystem::custombin::bin_dir}/cfbackup_${namespace}_${id}"
        $restore_cmd = "${::cfsystem::custombin::bin_dir}/cfrestore_${namespace}_${id}"

        $handler_opts = {
            path       => $path,
            backup_dir => $backup_dir,
        }

        ensure_resource('file', "${cfbackup::root_dir}/${namespace}", {
            ensure => directory,
            mode   => '0711',
        })

        file { $backup_cmd:
            mode    => '0700',
            content => epp('cfbackup/files_backup.sh.epp', $handler_opts)
        }
        -> file { $restore_cmd:
            mode    => '0700',
            content => epp('cfbackup/files_restore.sh.epp', $handler_opts)
        }
        -> file { $backup_dir:
            ensure => directory,
            mode   => '0700',
            owner  => root,
        }
        -> cfbackup::path { "${cfbackup::root_dir}/${namespace}/${id}":
            namespace => $namespace,
            id        => $id,
            type      => 'periodic_dump',
            compress  => $compress,
            prepare   => $backup_cmd,
        }
    } else {
        file { "${path}/backup.lock":
            mode    => '0440',
            owner   => getparam(File[$path], 'owner'),
            content => '',
        }

        cfbackup_path { $title:
            ensure    => present,
            namespace => $namespace,
            id        => $id,
            type      => $type,
            compress  => $compress,
            prepare   => $prepare,
        }
    }
}
