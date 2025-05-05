# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::SfbootAdapter')
require 'puppet/provider/sfboot_adapter/sfboot_adapter'

describe Puppet::Provider::SfbootAdapter::SfbootAdapter do
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
          adapter: 'enp196s0f0np0',
          link_speed: 'auto',
          linkup_delay: 5,
          banner_delay: 2,
          bootskip_delay: 5,
          boot_type: 'pxe',
          switch_mode: 'default',
          pf_count: 1,
          msix_limit: 32,
          vf_count: 0,
          vf_msix_limit: 8,
          pf_vlans: 'none',
          evt_cut_thru: 'default',
        },
        {
          adapter: 'enp196s0f1np1',
          link_speed: '10g',
          linkup_delay: 255,
          banner_delay: 255,
          bootskip_delay: 0,
          boot_type: 'disabled',
          switch_mode: 'partitioning-with-sriov',
          pf_count: 4,
          msix_limit: 32,
          vf_count: 2,
          vf_msix_limit: 8,
          pf_vlans: [0, 100, 110, 120],
          evt_cut_thru: 'disabled',
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
          '-i',
          'enp196s0f1np1',
          "link-speed=auto",
          "linkup-delay=5",
          "banner-delay=2",
          "bootskip-delay=5",
          "boot-type=pxe",
          "switch-mode=default",
          "pf-count=1",
          "msix-limit=32",
          "vf-count=0",
          "vf-msix-limit=8",
          "pf-vlans=none",
          "evt-cut-thru=default",
        ],
      ).and_return(fake_sfboot_output('enp196s0f1np1'))

      current = provider.get(context)

      provider.set(
        context,
        {
          'enp196s0f1np1' => {
            is: current.find { |r| r[:adapter] == 'enp196s0f1np1' },
            should: {
              adapter: 'enp196s0f1np1',
              link_speed: 'auto',
              linkup_delay: 5,
              banner_delay: 2,
              bootskip_delay: 5,
              boot_type: 'pxe',
              switch_mode: 'default',
              pf_count: 1,
              msix_limit: 32,
              vf_count: 0,
              vf_msix_limit: 8,
              pf_vlans: 'none',
              evt_cut_thru: 'default',
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
        EVT cut thru                          Default

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
        EVT cut thru                          Disabled

      (Partition map: TLV cursor in broken state initially)
      NIC_INFO

    if adapter
      header + info[adapter]
    else
      header + info.values.join("\n")
    end
  end
end
