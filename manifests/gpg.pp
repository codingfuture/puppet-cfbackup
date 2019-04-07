#
# Copyright 2019 (c) Andrey Galkin
#


# Please see README
class cfbackup::gpg(
    Array[String[1]]
        $recipients = [],
    Optional[String[1]]
        $own_key = undef,
    String[1]
        $own_key_id = $::facts['fqdn'],
) {
    $etc_dir = '/etc/cfbackup'
    $key_dir = '/etc/cfbackup/keys'
    $own_key_file = "${key_dir}/own.asc-key"
    $own_pubkey_file = "${key_dir}/own.asc"

    file { [ $etc_dir, $key_dir ]:
        ensure  => directory,
        mode    => '0700',
        purge   => true,
        recurse => true,
    }

    if $own_key {
        file { $own_key_file:
            mode    => '0600',
            replace => false,
            content => $own_key,
        }
        -> exec { 'cfbackup-gpg-key':
            command => [
                '/usr/bin/gpg',
                "--import ${own_key_file}",
            ].join(' '),
            unless  => [
                '/usr/bin/gpg',
                "--list-keys ${own_key_id}",
            ].join(' '),
        }
    } else {
        exec { 'cfbackup-gpg-key':
            command => [
                '/usr/bin/gpg',
                '--batch --yes --passphrase ""',
                "--quick-generate-key ${own_key_id}",
            ].join(' '),
            unless  => [
                '/usr/bin/gpg',
                "--list-keys ${own_key_id}",
            ].join(' '),
        }
        -> exec { $own_key_file:
            creates => $own_key_file,
            command => [
                '/usr/bin/gpg',
                "--armor --output ${own_key_file}",
                "--export-secret-keys ${own_key_id}",
            ].join(' ')
        }
        -> file { $own_key_file:
            mode    => '0600',
            replace => false,
            content => '',
        }
    }

    Exec['cfbackup-gpg-key']
    -> exec { $own_pubkey_file:
        creates => $own_pubkey_file,
        command => [
            '/usr/bin/gpg',
            "--armor --output ${own_pubkey_file}",
            "--export ${own_key_id}",
        ].join(' ')
    }
    -> file { $own_pubkey_file:
        mode    => '0600',
        replace => false,
        content => '',
    }

    $recipient_args = flatten($recipients.map |$idx, $key| {
        $key_file = "${key_dir}/r${idx}.asc"

        file { $key_file:
            mode    => '0600',
            content => $key,
        }

        ['--recipient-file', $key_file]
    }) + ['--recipient-file', $own_pubkey_file]

    file { $cfbackup::encrypt_helper:
        mode    => '0500',
        content => epp('cfbackup/gpg_encrypt.sh.epp'),
    }
    file { $cfbackup::decrypt_helper:
        mode    => '0500',
        content => epp('cfbackup/gpg_decrypt.sh.epp'),
    }
}
