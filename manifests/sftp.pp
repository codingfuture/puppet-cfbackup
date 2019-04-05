#
# Copyright 2019 (c) Andrey Galkin
#

class cfbackup::sftp() {
    fail('Not yet implemented!')

    file { $cfbackup::upload_helper:
        mode    => '0500',
        content => [
            '#!/bin/dash',
            'exit 1',
        ].join("\n"),
    }
}

