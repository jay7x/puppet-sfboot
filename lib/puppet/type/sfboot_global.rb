# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'sfboot_global',
  docs: <<-EOS,
@summary Manage Solarflare global Boot ROM parameters

@example Manage global parameters
  sfboot_global { 'global':
    boot_image       => 'all',
    port_mode        => '[2x10/25g][2x10/25g]',
    firmware_variant => 'full-feature',
  }

This resource type provides Puppet with the capabilities to manage global
Solarflare NIC Boot ROM parameters using `sfboot` tool. The only accepted
resource title is 'global'. It'll throw an error if any other title is
specified.

NOTE: This resource type manages only global parameters. For per-adapter Boot
ROM parameters, see `sfboot_adapter` type.

EOS
  features: ['supports_noop'],
  attributes: {
    boot_image: {
      type: "Enum['all','optionrom','uefi','disabled']",
      desc: 'Specifies which boot firmware images are served-up to the BIOS during start-up',
    },
    port_mode: {
      type: "Variant[Enum['default'], String[1]]",
      desc: 'Configure the port mode to use',
    },
    firmware_variant: {
      type: "Enum['full-feature','ultra-low-latency','capture-packed-stream','dpdk','auto']",
      desc: 'Configure the firmware variant to use',
    },
    insecure_filters: {
      type: "Enum['default','enabled','disabled']",
      desc: 'Grant or revoke a privilege to bypass on filter security for non-privileged functions on this port',
    },
    mac_spoofing: {
      type: "Enum['default','enabled','disabled']",
      desc: 'If enabled, non-privileged functions can create unicast filters for MAC addresses that are not associated with them',
    },
    rx_dc_size: {
      type: 'Variant[Integer[8,8], Integer[16,16], Integer[32,32], Integer[64,64]]',
      desc: 'Specifies the size of the descriptor cache for each receive queue',
    },
    change_mac: {
      type: "Enum['default','enabled','disabled']",
      desc: 'Change the unicast MAC address for a non-privileged function on this port.',
    },
    tx_dc_size: {
      type: 'Variant[Integer[8,8], Integer[16,16], Integer[32,32], Integer[64,64]]',
      desc: 'Specifies the size of the descriptor cache for each transmit queue',
    },
    vi_count: {
      type: 'Integer[0]',
      desc: 'Sets the total number of virtual interfaces that will be available on the NIC',
    },
    event_merge_timeout: {
      type: "Variant[Enum['default'], Integer[0]]",
      desc: 'Specifies the timeout (in nanoseconds) for RX event merging',
    },
    name: {
      type: 'String',
      desc: 'Unused, must be always set to "global"',
      behaviour: :namevar,
    },
  },
)
