# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'sfboot_adapter',
  docs: <<-EOS,
@summary Manage Solarflare per-adapter Boot ROM parameters

@example Manage parameters of the `enp123s0f1` NIC
  sfboot_adapter { 'enp123s0f1':
    boot_type   => 'disabled',
    switch_mode => 'partitioning-with-sriov',
    vf_count    => 2,
    pf_count    => 4,
    pf_vlans    => [0, 100, 110, 120],
  }

This resource type provides Puppet with the capabilities to manage Solarflare
NIC Boot ROM per-adapter parameters using `sfboot` tool.

NOTE: This resource type manages per-adapter parameters only. For global Boot
ROM parameters, see `sfboot_global` type.
EOS
  features: ['supports_noop'],
  attributes: {
    adapter: {
      type: 'String[1]',
      desc: 'The Solarflare NIC name, parameters of which you want to manage.',
      behaviour: :namevar,
    },
    link_speed: {
      type: "Enum['auto','10g','1g','100m']",
      desc: 'Specifies the Network Link Speed of the Adapter.',
    },
    linkup_delay: {
      type: 'Integer[0,255]',
      desc: 'Specifies the delay (in seconds) the adapter defers its first connection attempt after booting',
    },
    banner_delay: {
      type: 'Integer[0,255]',
      desc: 'Specifies the wait period (in seconds) for Ctrl-B to be pressed to enter adapter configuration tool',
    },
    bootskip_delay: {
      type: 'Integer[0,255]',
      desc: 'Specifies the time (in seconds) allowed for Esc to be pressed to skip adapter booting',
    },
    boot_type: {
      type: "Enum['pxe','disabled']",
      desc: 'Selects the adapter boot type (effective from next reboot)',
    },
    pf_count: {
      type: 'Integer[0]',
      desc: 'This is the number of available PCIe PFs on this physical network port',
    },
    msix_limit: {
      type: 'Variant[Integer[8,8], Integer[16,16], Integer[32,32], Integer[64,64], Integer[128,128], Integer[256,256], Integer[512,512], Integer[1024,1024]]',
      desc: 'Specifies the maximum number of MSI-X interrupts each PF may use',
    },
    vf_count: {
      type: 'Integer[0]',
      desc: 'This is the number of Virtual Functions advertised to the operating system for each Physical Function on this physical network port',
    },
    vf_msix_limit: {
      type: 'Variant[Integer[1,2], Integer[4,4], Integer[8,8], Integer[16,16], Integer[32,32], Integer[64,64], Integer[128,128], Integer[256,256]]',
      desc: 'Specifies the maximum number of MSI-X interrupts each VF may use',
    },
    pf_vlans: {
      type: "Variant[Enum['none'], Array[Integer[0,4094]]]",
      desc: 'Specifies a VLAN tag (or list of tags) for each PF on the port',
    },
    switch_mode: {
      type: "Enum['default','sriov','partitioning','partitioning-with-sriov','pfiov']",
      desc: 'Specifies the mode of operation that a port will be used in',
    },
    evt_cut_thru: {
      type: "Enum['default','disabled']",
      desc: 'Optionally disable usage of EVT cut thru',
    },
  },
)
