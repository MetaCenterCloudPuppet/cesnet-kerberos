##Kerberos

[![Build Status](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-kerberos.svg?branch=master)](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-kerberos) [![Puppet Forge](https://img.shields.io/puppetforge/v/cesnet/kerberos.svg)](https://forge.puppetlabs.com/cesnet/kerberos)

####Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
2. [Setup - The basics of getting started with Kerberos](#setup)
    * [What cesnet-kereros module affects](#what-kerberos-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with Kerberos](#beginning-with-kerberos)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
    * [Facts](#facts)
    * [Resource Types](#resources)
    * [Module Parameters (hadoop class)](#class-hadoop)
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
* Services: MIT Kerberos services as needed (kadmin, krb5kdc, kprop)

<a name="setup-requirements"></a>
###Setup Requirements

Puppet >= 3.x.

There are required passwords in parameters:

* *master\_password*: master password for KDC database (needed only during initial bootstrap)
* TODO: *remote\_password*: password for remote admin principal (needed only during initial bootstrap)

Parameters can be removed after the complete installation.

<a name="beginning-with-kerberos"></a>
###Beginning with Kerberos

    $kadmin_hostname = "kadmin.${domain}"
    $kdc_hostnames = [
    	"kdc1.${domain}",
    	"kdc2.${domain}",
    ]
    
    class{'kerberos':
    	kadmin_hostname   => $kadmin_hostname,
    	kdc_hostnames     => $kdc_hostnames,
    	master_password   => 'strong-master-password',
    	realm             => 'MONKEY_ISLAND',
    }

Note: *kadmin\_hostname* is automatically added to KDC hostnames in *krb5.conf*. This is needed for bootstrapping process - copying Kerberos host keys from admin server to KDC slaves using Kerberos KDC on the admin server.

<a name="usage"></a>
##Usage

By default the main *kerberos* class install services according to set hostnames. It is possible to disable it by *perform* parameter and place particular classes on the nodes manually.

TODO: perform=false, overrides for krb5.conf (DNS aliases) and kdc.conf (algorithms).

<a name="reference"></a>
##Reference

<a name="classes"></a>
###Classes

* [**`kerberos`**](#class-kerberos): The main class
* ...

<a name="class-kerberos"></a>
### `kerberos` class

<a name="parameters"></a>
#### Parameters

#####`client_packages`

List of Kerberos client packages. Default: *$::kerberos::params::client\_packages*.

#####`client_properties`

Additional client parameters or overrides for *krb5.conf*. Default: undef.

Example:

    client_properties => {
    	'realms' => {
    		'MONKEY_ISLAND' => {
    			'kdc' => ['kadmin-alias', 'kdc-alias1', 'kdc-alias2'],
    			'admin_server' => 'kadmin-alias',
    		},
    	},
    },

#####`kadmin_service`

Kerberos admin server service name. Default: by platform.

#####`kadmin_packages`

Kerberos admin server packages. Default: by platform.

#####`kadmin_hostname`

Kerberos admin server hostname. Default: *$::fqdn*.

It should be real hostname, not DNS alias.

#####`kdc_conf`

KDC config file. Default: *"${::kerberos::kdc\_conf\_dir}/kdc.conf".

Limitation: no *kdc\_conf\_dir* parameter.

#####`kdc_service`

KDC service name. Default: by platform.

#####`kdc_packages`

KDC packages name. Default: by plaform.

#####`kdc_hostnames`

KDC hostnames. Default: *kadmin\_hostname* or *$::fqdn*.

It should be real hostnames, not DNS alias.

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

<a name="limitations"></a>
##Limitations

kadmin must be collocated with KDC, see [Beginning with Kerberos](#beginning-with-kerberos). *krb5.conf* can be overriden after the successfull installation. Another option is to bootstrap manually - copying host keys from admin server to KDC slaves.

TODO: kerberos resource for principal and boostrap process is not implemented. For now the manual intervention is still needed.

There is no special care for the password parameters (*master\_password*, *remote\_password*).

<a name="development"></a>
##Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-kerberos](https://github.com/MetaCenterCloudPuppet/cesnet-kerberos)
