#
# Copyright 2019 (c) Andrey Galkin
#


class cfbackup::local() {
    # noop

    file { $cfbackup::upload_helper:
        mode    => '0550',
        content => '#!/bin/dash',
    }
    file { $cfbackup::download_helper:
        mode    => '0550',
        content => '#!/bin/dash',
    }
}
