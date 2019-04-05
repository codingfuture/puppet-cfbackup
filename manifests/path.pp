#
# Copyright 2019 (c) Andrey Galkin
#

define cfbackup::path(
    String[1]
        $namespace,
    String[1]
        $id,
    Enum['raw', 'periodic_dump']
        $type,
    Boolean
        $compress = true,
    Optional[String[1]]
        $prepare = undef,
) {
    $path = $title

    file { "${path}/backup.lock":
        mode    => '0440',
        owner   => getparam(File[$path], 'owner'),
        content => '',
    }
}
