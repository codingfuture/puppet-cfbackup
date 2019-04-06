#
# Copyright 2019 (c) Andrey Galkin
#

class cfbackup::sftp(
    String[1]
        $user,
    String[1]
        $host,
    String[1]
        $ssh_key,
    Cfnetwork::Port
        $port = 22,
) {
    ensure_resource( 'cfsystem::sshdir', 'root' )
    ensure_packages(['openssh-client'])

    $ssh_dir = '/root/.ssh'
    $ssh_idkey = "${ssh_dir}/id_backup"

    file { $ssh_idkey:
        mode    => '0600',
        content => $ssh_key,
    }
    -> file { "${ssh_dir}/config_backup":
        mode    => '0600',
        content => [
            'Host backuphost',
            "   User ${user}",
            "   Hostname ${host}",
            "   Port ${port}",
            "   IdentityFile ${ssh_idkey}",
            '   ControlPath ~/.ssh/master-backuphost',
            '   ControlPersist 10s',
            '   ControlMaster auto',
            '',
        ].join("\n"),
    }

    file { $cfbackup::upload_helper:
        mode    => '0500',
        content => epp('cfbackup/sftp_upload.sh.epp'),
    }
    file { $cfbackup::download_helper:
        mode    => '0500',
        content => epp('cfbackup/sftp_download.sh.epp'),
    }

    cfnetwork::describe_service { 'cfbackup_sftp':
        server => "tcp/${port}",
    }
    cfnetwork::client_port { 'any:cfbackup_sftp':
        user => root,
    }
}

