# Puppet sfboot module

## Table of Contents

1. [Description](#description)
1. [Setup](#setup)
    * [Setup requirements](#setup-requirements)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Links](#limitations)

## Description

This module contains Puppet resource types and classes to manage
Solarflare NIC Boot ROM parameters using `sfboot` tool.

Please check the [Limitations](#limitations) section below.

## Setup

### Setup Requirements

`sfboot` tool must be present on the nodes you'd like to use this module on.

See [Drivers and Software download page](https://www.xilinx.com/support/download/nic-software-and-drivers.html#drivers-software)
on how to install the Solarflare utilities.

## Usage

Use `sfboot_adapter` Puppet resource type to manage per-adapter Solaflare NIC
Boot ROM parameters.

```puppet
sfboot_adapter { 'enp123s0f1':
  boot_type   => 'disabled',
  switch_mode => 'partitioning-with-sriov',
  vf_count    => 2,
  pf_count    => 4,
  pf_vlans    => [0, 100, 110, 120],
}
```

Use `sfboot_global` Puppet resource type to manage global Solaflare NIC Boot
ROM parameters.

```puppet
sfboot_global { 'global':
  boot_image       => 'all',
  port_mode        => '[2x10/25g][2x10/25g]',
  firmware_variant => 'full-feature',
}
```

Please note, that `sfboot_global` resource can only accept `global` title. It'll throw an error if any other title is specified.

## Reference

See [REFERENCE.md](https://github.com/jay7x/puppet-sfboot/blob/main/REFERENCE.md).

## Limitations

* As stated before, Solarflare utilities installation is not implemented (yet).
* Author is not aware how to read the `permit-fw-downgrade` global parameter
  value. That's why it's not supported.
* Rebooting the node after changing Boot ROM parameters is out of the module
  scope.
* This module was never tested with multiple Solarflare cards on the same
  server.
* This module is tested with `sfboot` tool v8.2.4
* This module is tested on the following OS list at the moment:
  * Debian 11, 12

## Links

1. [Drivers and Software download page](https://www.xilinx.com/support/download/nic-software-and-drivers.html#drivers-software)
