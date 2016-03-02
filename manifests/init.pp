class nexus (
  $source  = 'http://buildsources.delivery.puppetlabs.net/tools/',
  $dest    = '/var/www',
  $version = '2.12.0-01',
  $port    = '8081',
) {
  $source_url = "${source}/nexus-${version}-bundle.tar.gz"

  $nexus_port = $port

  include java

  file { $dest:
    ensure  => 'directory',
    recurse => 'true'
  }

  exec { 'nexus-download':
    command => "curl -v -L --progress-bar -o '/tmp/nexus-${version}-bundle.tar.gz' '${source_url}'",
    cwd     => '/tmp',
    path    => [ '/bin', '/usr/bin' ],
    creates => "/tmp/nexus-${version}-bundle.tar.gz",
    unless  => "test -d ${dest}/nexus-${version}"
  }

  exec { 'nexus-extract':
    command   => "tar -C ${dest} -zxvf /tmp/nexus-${version}-bundle.tar.gz",
    cwd       => '/tmp',
    path      => [ '/bin', '/usr/bin' ],
    creates   => "${dest}/nexus-${version}",
    subscribe => Exec[ 'nexus-download' ],
    require   => Exec[ 'nexus-download' ]
  }

  file { '/etc/init.d/nexus':
    ensure => 'link',
    target => "${dest}/nexus-${version}/bin/nexus"
  }

  service { 'nexus':
    ensure => 'running',
    enable => 'true'
  }

  file { '$dest/nexus-${version}/conf/nexus.properties':
    ensure  => 'file',
    mode    => '0700',
    owner   => 'root',
    group   => 'root',
    content => template("${module_name}/nexus-properties.erb"),
    notify  => Service['nexus'],
  }
}
