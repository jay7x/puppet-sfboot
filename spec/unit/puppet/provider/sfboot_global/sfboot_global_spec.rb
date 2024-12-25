# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::SfbootGlobal')
require 'puppet/provider/sfboot_global/sfboot_global'

describe Puppet::Provider::SfbootGlobal::SfbootGlobal do
  subject(:provider) { described_class.new }

  let(:context) do
    c = instance_double('Puppet::ResourceApi::BaseContext', 'context')
    allow(c).to receive(:debug)

    # Call the original block in the provider `set()` implementation
    allow(c).to receive(:updating) do |name, &block|
      block.call(name)
    end

    c
  end

  describe '#get' do
    it 'processes resources' do
      expect(Puppet::Util::Execution).to receive(:execute).with(['sfboot']).and_return(fake_sfboot_output)

      expect(provider.get(context)).to eq [
        {
          name: 'global',
          boot_image: 'all',
          port_mode: '[4x10/25g]',
          firmware_variant: 'full-feature',
          insecure_filters: 'default',
          mac_spoofing: 'default',
          change_mac: 'default',
          rx_dc_size: 32,
          tx_dc_size: 16,
          vi_count: 2048,
          event_merge_timeout: 1500,
        },
      ]
    end
  end

  describe '#set' do
    it 'updates the resource' do
      # get() call
      expect(Puppet::Util::Execution).to receive(:execute).with(['sfboot']).and_return(fake_sfboot_output)
      # set() call
      expect(Puppet::Util::Execution).to receive(:execute).with(
        [
          'sfboot',
          "'boot-image=disabled'",
          "'port-mode=[2x10/25g][2x10/25g]'",
          "'firmware-variant=ultra-low-latency'",
          "'insecure-filters=enabled'",
          "'mac-spoofing=disabled'",
          "'change-mac=enabled'",
          "'rx-dc-size=64'",
          "'tx-dc-size=32'",
          "'vi-count=1024'",
          "'event-merge-timeout=1234'",
        ],
      ).and_return(fake_sfboot_output)

      current = provider.get(context)

      provider.set(
        context,
        {
          'global' => {
            is: current[0],
            should: {
              name: 'global',
              boot_image: 'disabled',
              port_mode: '[2x10/25g][2x10/25g]',
              firmware_variant: 'ultra-low-latency',
              insecure_filters: 'enabled',
              mac_spoofing: 'disabled',
              change_mac: 'enabled',
              rx_dc_size: 64,
              tx_dc_size: 32,
              vi_count: 1024,
              event_merge_timeout: 1234,
            },
          },
        },
      )
    end
  end

  # Simulates fake sfboot output for 2 adapters
  def fake_sfboot_output(adapter = nil)
    header = <<~HEADER
      Fake sfboot utility [v8.2.4]
      Copyright 2002-2020 Fake Xilinx, Inc.

    HEADER

    info = {}
    info['enp196s0f0np0'] = <<~NIC_INFO
      enp196s0f0np0:
        Boot image                            Option ROM and UEFI
          Link speed                          Negotiated automatically
          Link-up delay time                  5 seconds
          Banner delay time                   2 seconds
          Boot skip delay time                5 seconds
          Boot type                           PXE
        Physical Functions on this port       1
        PF MSI-X interrupt limit              32
        Virtual Functions on each PF          0
        VF MSI-X interrupt limit              8
        Port mode                             [4x10/25G]
        Firmware variant                      Full feature / virtualization
        Insecure filters                      Default
        MAC spoofing                          Default
        Change MAC                            Default
        VLAN tags                             None
        Switch mode                           Default
        RX descriptor cache size              32
        TX descriptor cache size              16
        Total number of VIs                   2048
        Event merge timeout                   1500 nanoseconds

      (Partition map: TLV cursor in broken state initially)
      NIC_INFO

    info['enp196s0f1np1'] = <<~NIC_INFO
      enp196s0f1np1:
        Boot image                            Option ROM and UEFI
          Link speed                          10G bits/second
          Link-up delay time                  255 seconds
          Banner delay time                   255 seconds
          Boot skip delay time                0 seconds
          Boot type                           Disabled
        Physical Functions on this port       4
        PF MSI-X interrupt limit              32
        Virtual Functions on each PF          2
        VF MSI-X interrupt limit              8
        Port mode                             [4x10/25G]
        Firmware variant                      Full feature / virtualization
        Insecure filters                      Default
        MAC spoofing                          Default
        Change MAC                            Default
        VLAN tags                             0,100,110,120
        Switch mode                           Partitioning with SR-IOV
        RX descriptor cache size              32
        TX descriptor cache size              16
        Total number of VIs                   2048
        Event merge timeout                   1500 nanoseconds

      (Partition map: TLV cursor in broken state initially)
      NIC_INFO

    if adapter
      header + info[adapter]
    else
      header + info.values.join("\n")
    end
  end
end
