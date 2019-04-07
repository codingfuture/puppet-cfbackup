# cfbackup - System backup & restore management

## Description

Generic configuration of system backup:

* Remote locations:
    - `local` - for NFS-like mounts (noop)..
    - `sftp` - for SSH-based uploads/downloads.
    - `s3` - for S3 uploads/downloads.
* Encryption:
    - asymmetric multi-recipient GPG.
    - ensures high data privacy.
    - allows recovery via offsite secure keys.
    - allows recovery via local host key.
    - allows sharing remote backup location with other hosts without jeopardizing data privacy.
* Periodic backup strategy:
    - service-specific backup and restore procedures are implemented in other modules.
    - timer-based periodic whole system backup is run (hourly by default).
    - timer-based periodic upload is run (daily by default).
    - periodic backup is aware of base and incremental backup approaches.
    - automatic cleanup of local backups.
    - proper file locking is ensured.
* File backup strategy:
    - use `rdiff-backup` for base & incremental periodic dumps.

### Terminology & Concept

There are three major types of data for backup:

* Databases:
    - requires custom backup procedures for efficiency and integrity purposes.
* Filesystem:
    - raw file copying is acceptable.
* Applications:
    - dummy backup may help with fast recovery, but proper restoration procedure is just a new deployment.

Locations:

* `/mnt/backup` - root for all local backups:
    - desired to be a separate partition or an efficient network mount.
* `/mnt/backup/{namespace}/{id}/` - root of service backups:
    - `{namespace}` - service namespace, e.g. `cfdb`.
    - `{id}` - service ID in the namespace, e.g. CFDB cluster name.
* `/mnt/backup/{namespace}/{id}/{base-datetime}` - location of base backups.
    - incremental backup data is assumed to be inside.
* `/mnt/backup/{namespace}/{id}/last_backup` - hold value of the last `{base-datetime}`.
* `{remote}/{hostname}/{namespace}/{id}/` - root for remote backups.

Primary CLI commands:

* `cfbackup_all` - perform local backup of services configured via `cfbackup::path`
* `cfbackup_upload_all` - perform upload and cleanup of local backups.
* `cfbackup_download_latest [path]` - download the latest available backup for later local restore.

System services:

* `cftimer-backupall` - run cfbackup_all`
* `cftimer-uploadall` - run cfbackup_upload_all`

Helpers CLI commands:

* `cfbackup_encrypt_helper` and `cfbackup_decrypt_helper` - encryption processing.
* `cfbackup_upload_helper` and `cfbackup_download_helper` - remote transfer processing.
* `cfbackup_periodic_helper.sh` - common logic to perform a single service backup.
* `cfrestore_periodic_helper.sh` - common logic to perform a single service restore.

## Technical Support

* [Example configuration](https://github.com/codingfuture/puppet-test)
* Free & Commercial support: [support@codingfuture.net](mailto:support@codingfuture.net)

## Setup

Up to date installation instructions are available in Puppet Forge: https://forge.puppet.com/codingfuture/cfbackup

Please use [librarian-puppet](https://rubygems.org/gems/librarian-puppet/) or
[cfpuppetserver module](https://codingfuture.net/docs/cfpuppetserver) to deal with dependencies.

There is a known r10k issue [RK-3](https://tickets.puppetlabs.com/browse/RK-3) which prevents
automatic dependencies of dependencies installation.

## Examples

Please check [codingufuture/puppet-test](https://github.com/codingfuture/puppet-test) for
example of a complete infrastructure configuration and Vagrant provisioning.

```yaml
classes:
    - cfbackup

cfbackup::gpg::recipients:
    - |
        Offsite public key 1
    - |
        Offsite public key 2

# SFTP remote upload
#-------------------
cfbackup::type: sftp
cfbackup::sftp::user: sftp_user
cfbackup::sftp::host: sftp.example.com
cfbackup::sftp::port: 22
cfbackup::sftp::ssh_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----

# S3 remote upload
#-------------------
cfbackup::type: s3
cfbackup::s3::url: https://s3.example.com
cfbackup::s3::bucket: backup.example.com
cfbackup::s3::access_key: test123
cfbackup::s3::secret_key: test234
```

## Implicitly created resources

```yaml
# for SFTP
#------------------
cfnetwork::describe_service:
    cfbackup_sftp:
        server: "tcp/${port}"
cfnetwork::client_port:
    "any:cfbackup_sftp":
        user: root
```

## `cfbackup` parameters

### class `cfbackup`

* `Enum['s3', 'sftp', 'local'] $type = 'local'` - type of remote transfer.
* `Enum['gpg'] $crypt = 'gpg'` - type of encryption.
* `String[1] $root_dir = '/mnt/backup'` - local location for periodic backups.
* `String[1] $backup_timer = 'hourly'` - systemd `OnCalendar` configuration for `cftimer-backupall`.
* `String[1] $upload_timer = 'daily'` - systemd `OnCalendar` configuration for `cftimer-uploadall`.
* `Integer[0] $reserve_ram = 64` - amount of system memory to reserve for backup processing.

### resource `cfbackup::path`

This resource type should be used to register service backup procedures.

* `String[1] $namespace` - service namespace.
* `String[1] $id` - unique service identifier in the namespace.
* `Enum['files', 'periodic_dump'] $type` - type of backup.
* `Boolean $compress = true` - should compression be applied (bzip2).
* `Optional[String[1]] $prepare = undef` - command to execute during `cfbackup_all`.

### class `cfbackup::gpg`

Backup encryption and decryption configuration.

* `Array[String[1]] $recipients = []` - list of additional public keys for encryption.
* `Optional[String[1]] $own_key = undef` - forced private key for local host.
* `String[1] $own_key_id = $::facts['fqdn']` - identifier to use for local host key.

### class `cfbackup::sftp`

Remote SFTP endpoint configuration.

* `String[1] $user` - SSH user name
* `String[1] $host` - SSH host
* `String[1] $ssh_key` - private SSH key
* `Cfnetwork::Port $port = 22` - SSH port

### class `cfbackup::s3`

Remote S3 endpoint configuration.

* `String[1] $url` - S3 URL
* `String[1] $bucket` - S3 bucket
* `String[1] $access_key` - S3 access key
* `String[1] $secret_key` - S3 secret key
* `String[1] $s3cmd_version = 'latest'` - version of `s3cmd` to use
