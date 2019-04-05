#
# Copyright 2019 (c) Andrey Galkin
#


class cfbackup::s3(
    String[1]
        $url,
    String[1]
        $bucket,
    String[1]
        $access_key,
    String[1]
        $secret_key,
    String[1]
        $s3cmd_version = 'latest',
) {
    include cfsystem::pip
    include cfsystem::custombin

    $s3cmd = '/usr/local/bin/s3cmd'
    $s3upload = "${cfsystem::custombin::bin_dir}/cfbackup_s3_upload"
    $s3restore = "${cfsystem::custombin::bin_dir}/cfbackup_s3_recover"

    $s3params = {
        url        => $url,
        bucket     => $bucket,
        access_key => $access_key,
        secret_key => $secret_key,
        hostname   => $::facts['fqdn'],
    }

    Anchor['cfsystem-pip-install']
    -> package { 's3cmd':
        ensure   => $s3cmd_version,
        provider => cfpip2,
        require  => Package['pip'],
    }
    -> file { $s3upload:
        mode    => '0500',
        content => epp('cfbackup/s3upload.sh.epp', $s3params)
    }
    -> file { $s3restore:
        mode    => '0500',
        content => epp('cfbackup/s3restore.sh.epp', $s3params)
    }
    -> file { $cfbackup::upload_helper:
        mode    => '0500',
        content => [
            '#!/bin/dash',
            "${s3upload} \"\$@\"",
        ].join("\n"),
    }
}
