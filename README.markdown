##Kerberos

[![Build Status](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-kerberos.svg?branch=master)](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-kerberos) [![Puppet Forge](https://img.shields.io/puppetforge/v/cesnet/kerberos.svg)](https://forge.puppetlabs.com/cesnet/kerberos)

####Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
2. [Setup - The basics of getting started with Kerberos](#setup)
    * [What cesnet-kerberos module affects](#what-kerberos-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with Kerberos](#beginning-with-kerberos)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
    * [Resource Types](#resources)
     * [kerberos::keytab](#resource-kerberos_keytab)
     * [kerberos::policy](#resource-kerberos_policy)
     * [kerberos::principal](#resource-kerberos_principal)
     * [kerberos\_policy](#resource-kerberos_policy)
     * [kerberos\_principal](#resource-kerberos_principal)
    * [Module Parameters (kerberos class)](#class-kerberos)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

<a name="module-description"></a>
##Module Description

This module deploys MIT Kerberos client and servers.

<a name="setup"></a>
##Setup

<a name="what-kerberos-affects"></a>
###What cesnet-kerberos module affects

* Files modified:
 * */etc/krb5.conf*
 * */etc/krb5kdc* or */var/kerberos/krb5kdc* directory: *kdc.conf*, stash file, ...
 * */var/lib/krb5kdc* or */var/kerberos/krb5kdc* directory: Kerberos database
 * */usr/local/sbin/kerberos-kprop-all*: propagation script on Kerberos admin server
* Packages: MIT Kerberos packages as needed (client, kadmin, krb5kdc, kpropd)
* Services: MIT Kerberos services as needed (kadmin, krb5kdc, kpropd)

<a name="setup-requirements"></a>
###Setup Requirements

Puppet >= 3.x.

There are required passwords in parameters:

* *master\_password*: master password for KDC database (needed only during initial bootstrap)

For multi node setup:

* *admin\_principal*: admin principal name
* *admin\_password*: password for remote admin principal (needed only during initial bootstrap)

Parameters could be removed after the complete installation.

<a name="beginning-with-kerberos"></a>
###Beginning with Kerberos

Everything on one machine (client, admin server, KDC server):

    class{'kerberos':
      kadmin_hostname => $::fqdn,
      master_password => 'strong-master-password',
      realm           => 'MONKEY_ISLAND',
    }

    node default {
      $princ = "host/${::fqdn}@${::kerberos::realm}"
      kerberos::principal{$princ:
        ensure     => present,
        attributes => {
          requires_preauth => true,
        },
        policy     => 'default_host',
      }
      -> kerberos::keytab{'/etc/krb5.keytab':
        principals => [$princ],
      }

      kerberos::policy{'default':
        ensure     => 'present',
        minlength  => 6,
        history    => 2,
        maxlife    => '365 days 0:00:00',
      }

      kerberos::policy{'default_host':
        ensure     => 'present',
        minlength  => 8,
      }
    }

Note: as seen in the example: all principals and keytab needs to be specified.

<a name="usage"></a>
##Usage

### Multi-KDC setup

More advanced usage with multiple KDC servers and separated clients:

    include ::stdlib

    $kadmin_hostname = "kadmin.${domain}"
    $kdc_hostnames = [
      "kadmin.${domain}",
      "kdc1.${domain}",
      "kdc2.${domain}",
    ]
    $realm = 'MONKEY_ISLAND'
    $host_principals = suffix(prefix($kdc_hostnames, 'host/'), "@${realm}")

    class{'kerberos':
      kadmin_hostname   => $kadmin_hostname,
      kdc_hostnames     => $kdc_hostnames,
      admin_principal   => "puppet/admin@${realm}",
      admin_password    => 'good-password',
      master_password   => 'strong-master-password',
      realm             => $realm,
    }

    node 'kadmin' {
      kerberos::principal{$host_principals:
        ensure     => 'present',
        attributes => {
          'requires_preauth' => true,
        },
        policy     => 'default_host',
      }
      ->kerberos::keytab{'/etc/krb5.keytab':
        principals => ["host/${::fqdn}@${realm}"],
      }

      kerberos::principal{$::kerberos::admin_principal:
        ensure     => 'present',
        attributes => {
          'requires_preauth' => true,
        },
        password   => $::kerberos::admin_password,
        policy     => 'default_host',
      }

      kerberos::policy{'default_host':
        ensure    => 'present',
        minlength => 6,
      }

      kerberos::policy{'default':
        ensure    => 'present',
        history   => 2,
        minlength => 6,
        maxlife   => '365 days 0:00:00',
      }

      cron{'kprop-all':
        command     => '/usr/local/sbin/kerberos-kprop-all > /var/log/kerberos-kprop-all.log 2>&1',
        environment => 'PATH=/sbin:/usr/sbin:/bin:/usr/bin',
        hour        => '*',
        minute      => 0,
      }
    }

    node /kdc\d+/ {
      # this will use kerberos::admin_principal and kerberos::admin_password parameters
      kerberos::keytab{'/etc/krb5.keytab':
        principals => ["host/${::fqdn}@${realm}"],
        wait       => 600,
      }
    }

    # all clients
    node default {
      # this will use kerberos::admin_principal and kerberos::admin_password parameters
      kerberos::principal{"host/${::fqdn}@${realm}":
        ensure          => 'present',
        attributes      => {
          'requires_preauth' => true,
        },
        policy          => 'default_host',
      }
      ->kerberos::keytab{'/etc/krb5.keytab':
        principals => ["host/${::fqdn}@${realm}"],
      }
    }

Note: **bootstrap**:

For bootstrap process to work, the Kerberos admin server (*kadmin\_hostname*) should be also a KDC server (in *kdc\_hostnames*). This way the Kerberos host keys can be distributed from admin server to KDC slaves using Kerberos KDC on the admin server. Also *admin\_principal* and *admin\_password* are required.

Several iterations must be performed before deployment is successfully finished:

1. (will fail) Kerberos admin server initial database setup + creating admin and KDC host keys
2. (will wait on KDCs) KDC server setup + fetch host keys created in (1.) into keytabs
3. (success after all KDC ready) propagate database from admin server to slave KDCs using */usr/local/sbin/kerberos-kprop-all*
4. (success on KDCs after propagation from admin server) KDC server finalize - stash files for startup

Note 2: **principals and keytabs**

All principals and keytabs need to be explicitly created. Better is to put *kerberos::principal* resource at admin server to minimize admin password usage. *kerberos::keytab* on remote machines will use admin principal and password once during creating of the keytab files.

Note 3: **perform parameter**

By default the main *kerberos* class install services according to set hostnames. It is possible to disable it by *perform* parameter and place particular classes on the nodes manually.

Note 4: **kprop**

See the example cron job in *kadmin* node.

### DNS aliases

It is the best-practice to use DNS aliases in *krb5.conf*. Kerberos puppet module requires real hostnames in its parameters, but aliases can be set using client overrides:

    ...
    class{'kerberos':
      client_properties => {
        'realms' => {
          "${realm}" => {
            'kdc' => ['kadmin-alias', 'kdc1-alias', 'kdc2-alias'],
            'admin_server' => 'kadmin-alias',
          },
        },
      },
      kadmin_hostname   => $kadmin_hostname,
      kdc_hostnames     => $kdc_hostnames,
      ...
    }

### More Kerberos module resources examples

    kerberos::policy{'default':
      ensure               => 'present',
      minlength            => 6,
      history              => 2,
      maxlife              => '365 days 0:00:00',
      failurecountinterval => '0:00:00',
    }

    kerberos::principal{'hawking@EXAMPLE.COM':
      ensure     => 'present',
      attributes => {
        'allow_tix'        => true,
        'requires_preauth' => true,
      },
      policy     => 'default',
    }

Note: defaults

*default_attributes* and *default_policy* parameters on *kerberos* class can be used instead of parameters in *kerberos::principal*.

### krb5.conf only

    $kadmin_hostname = "KADMIN.example.com"
    $kdc_hostnames = [
      "KADMIN.example.com",
      "KDC1.example.com",
      "KDC2.example.com",
    ]

    class{'kerberos':
      kadmin_hostname   => $kadmin_hostname,
      kdc_hostnames     => $kdc_hostnames,
      realm             => 'EXAMPLE.COM',
      perform           => false,

      # realm-specific config file instead of global config
      #krb5_conf => '/etc/krb5.conf.d/example_com'
    }

    include ::kerberos::client::config

<a name="reference"></a>
##Reference

<a name="classes"></a>
###Classes

* [**`kerberos`**](#class-kerberos): The main class
* **`kerberos::client`**: Kerberos client
* `kerberos::client::config`
* `kerberos::client::install`
* `kerberos::client::service`
* **`kerberos::kadmin`**: kadmin server
* `kerberos::kadmin::config`
* `kerberos::kadmin::install`
* `kerberos::kadmin::service`
* **`kerberos::kdc`**: KDC server
* `kerberos::kdc::config`
* `kerberos::kdc::install`
* `kerberos::kdc::service`
* **`kerberos::kprop`**: kpropd server
* `kerberos::kprop::config`
* `kerberos::kprop::install`
* `kerberos::kprop::service`
* `kerberos::params`

<a name="class-kerberos"></a>
### `kerberos` class

<a name="parameters"></a>
#### Parameters

#####`acl`

ACL to Kerberos database. Default: "${admin\_principal} admcil" for everything.

#####`admin_password`

Password of the principal for remote access to KDC. Default: undef.

**Required** for initial bootstrap of multiple KDC servers.

#####`admin_principal`

Principal name for remote access to KDC. Default: undef.

**Required** for initial bootstrap of multiple KDC servers.

#####`admin_keytab`

Keytab for remote access to KDC. Default: undef.

#####`client_packages`

List of Kerberos client packages. Default: *$::kerberos::params::client\_packages*.

#####`client_properties`

Additional client parameters or overrides for *krb5.conf*. Default: undef.

Example:

    client_properties => {
      'realms' => {
        'MONKEY_ISLAND' => {
          'kdc' => ['kadmin-alias', 'kdc1-alias', 'kdc2-alias'],
          'admin_server' => 'kadmin-alias',
        },
      },
    },

#####`default_attributes`

Default attributes used in *kerberos::principal* resource. Default: undef.

#####`default_policy`

Default policy name used in *kerberos::principal* resource. Default: undef.

#####`domain`

Realm DNS domain. Default: *$::domain*.

#####`kadmin_service`

Kerberos admin server service name. Default: by platform.

#####`kadmin_packages`

Kerberos admin server packages. Default: by platform.

#####`kadmin_hostname`

Kerberos admin server hostname. Default: *$::fqdn*.

It should be real hostname, not DNS alias. See *client\_properties* for aliases usage.

#####`kdc_conf`

KDC config file. Default: *"${::kerberos::kdc\_conf\_dir}/kdc.conf".

Limitation: no *kdc\_conf\_dir* parameter.

#####`kdc_service`

KDC service name. Default: by platform.

#####`kdc_packages`

KDC packages name. Default: by platform.

#####`kdc_hostnames`

KDC hostnames. Default: *kadmin\_hostname* or *$::fqdn*.

It should be real hostnames, not DNS aliases. See *client\_properties* for aliases usage.

#####`kdc_properties`

Additional parameters or overrides for *kdc.conf*. Default: undef.

Example:

    kdc_properties => {
      'realms' => {
        'MONKEY_ISLAND' => {
          'supported_enctypes' => 'aes256-sha1:normal aes128-sha1:normal des3-cbc-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal',
        },
      },
    },

#####`krb5_conf`

Main kerberos client config file. Default: '/etc/krb5.conf'.

Example:

    krb5_conf => '/etc/krb5.conf.d/monkey-island.conf',

#####`master_password`

KDC database master password. Default: undef.

**Required** for initial bootstrap.

#####`perform`

Automagically deploy all services on the nodes. Default: true.

#####`realm`

Kerberos realm name. Required.

<a name="resources"></a>
###Resource Types

* [**`kerberos::keytab`**](#resource-kerberos_keytab): Kerberos keytab
* [**`kerberos::policy`**](#resource-kerberos_policy): Kerberos policy (using parameters from *kerberos* class)
* [**`kerberos::principal`**](#resource-kerberos_principal): Kerberos principal (using parameters from *kerberos* class)
* [**`kerberos_principal`**](#resource-kerberos_principal): Kerberos principal
* [**`kerberos_policy`**](#resource-kerberos_policy): Kerberos policy on admin server

<a name="resource-kerberos_principal"></a>
### `kerberos_principal` resource

Parameters for *kerberos::principal* are the same, except *admin\_keytab, admin\_password, admin\_principal*, which are taken from the main *kerberos* class parameters.

<a name="parameters"></a>
#### Parameters

#####`title`

Kerberos principal name

#####`admin_principal`

Admin principal. Default: undef.

The admin principal is added to ACL with "acmil" rights.

#####`admin_keytab`

Admin keytab. Default: undef.

Non-empty parameter will switch from *kadmin.local* do *kadmin* in resources.

#####`admin_password`

Admin password. Default: undef.

Non-empty parameter will switch from *kadmin.local* do *kadmin* in resources.

#####`attributes`

Kerberos principal attributes. Default: undef.

Hash of principal boolean attributes values. Specified attributes are compared with the real values and updated, if needed. Not specified attributes are not checked.

List of known attributes:

* *allow\_postdated*
* *allow\_forwardable*
* *allow\_tgs\_req*
* *allow\_renewable*
* *allow\_proxiable*
* *allow\_dup\_skey*
* *allow\_tix*
* *allow\_svr*
* *requires\_preauth*
* *requires\_hwauth*
* *needchange*
* *password\_changing\_service*
* *ok\_as\_delegate*
* *ok\_to\_auth\_as\_delegate*
* *no\_auth\_data\_required*
* *lockdown\_keys*

Example:

    attributes => {
      allow_tix        => true,
      requires_preauth => true,
    }

#####`local`

Prefer *kadmin.local* over *kadmin*. Default: (false when *admin\_keytab* or *admin\_password* parameters non-empty)

#####`password`

Kerberos principal password. Default: undef (=randomized key).

Passwords are not changed. This parameter is used only when creating a new Kerberos principal.

#####`policy`

Kerberos policy of the principal. Default: undef.

<a name="resource-kerberos_keytab"></a>
### `kerberos_keytab` resource

Parameters *admin\_keytab, admin\_password, admin\_principal* are taken from the main *kerberos* class parameters.

<a name="parameters"></a>
#### Parameters

#####`title`

Keytab file.

#####`principals`

Principals to add into keytab. Required.

#####`owner`

Keytab file owner. Default: undef.

#####`group`

Keytab file group. Default: undef.

#####`local`

Prefer *kadmin.local* over *kadmin*. Default: (autodetect by FQDN)

Requirements:

1. remote administration using *kadmin*: *kerberos::admin\_keytab* or *kerberos::admin\_password* parameter
2. local administration using *kadmin.local*: placement on Kerberos kadmin server

#####`mode`

Keytab file mode. Default: '0600'.

#####`wait`

Repeated tries time. Default: 0 (try once).

<a name="resource-kerberos_policy"></a>
### `kerberos_policy` resource

Parameters for *kerberos::policy* are the same, except *admin\_keytab, admin\_password, admin\_principal*, which are taken from the main *kerberos* class parameters.

The times can be specified as:

* number of seconds
* *HH:MM:SS*
* *N day HH:MM:SS*
* *N days HH:MM:SS*

<a name="parameters"></a>
#### Parameters

#####`title`

Kerberos policy name.

#####`admin_password`

Password of the principal for remote access to KDC. Default: undef.

Non-empty parameter will switch from *kadmin.local* do *kadmin* in resources.

#####`admin_principal`

Principal name for remote access to KDC. Default: undef.

#####`admin_keytab`

Keytab for remote access to KDC. Default: undef.

Non-empty parameter will switch from *kadmin.local* do *kadmin* in resources.

#####`maxlife`

Maximum password life. Default: undef ('0 days 00:00:00').

#####`minlife`

Minimum password life. Default: undef ('0 days 00:00:00').

#####`minlength`

Minimum password length. Default: undef (1).

#####`minclasses`

Minimum number of password character classes. Default: undef (1).

#####`history`

Number of old keys kept. Default: undef (1).

#####`maxfailure`

Maximum password failures before lockout. Default: undef (0).

#####`failurecountinterval`

Password failure count reset interval. Default: undef ('0 days 00:00:00').

#####`lockoutduration`

Password lockout duration. Default: undef ('0 days 00:00:00').

<a name="limitations"></a>
##Limitations

For automatic bootstrap, kadmin must be collocated with KDC, see [Beginning with Kerberos](#beginning-with-kerberos). Another option is to bootstrap manually - copy host key and database from admin server to KDC slaves.

There is no special care for the password parameters (*master\_password*, *admin\_password*). After initial deployment, it is possible to remove *master\_password* from parameters. It will be needed only when adding another KDC server.

<a name="development"></a>
##Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-kerberos](https://github.com/MetaCenterCloudPuppet/cesnet-kerberos)
