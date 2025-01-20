# frozen_string_literal: true

require 'spec_helper'
require 'puppet_x/jay7x/sfboot/cli_helper'

describe PuppetX::Sfboot::CliHelper do
  let(:cli_helper) { described_class.new }
  let(:sfboot_params) do
    {
      'enp196s0f0np0' => {
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
      },
      'enp196s0f1np1' => {
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
      },
    }
  end

  describe '#read_params' do
    it 'runs sfboot and parses its output correctly' do
      expect(Puppet::Util::Execution).to receive(:execute).with(['sfboot']).and_return(fake_sfboot_output)

      expect(cli_helper.read_params).to eq(sfboot_params)
    end
  end

  describe '#set_attrs' do
    context 'without adapter specified' do
      let(:attrs) do
        {
          boot_image: 'uefi',
          port_mode: '[1x10/25g][1x10/25g]',
          firmware_variant: 'ultra-low-latency',
        }
      end

      it 'runs sfboot and parses its output correctly' do
        expect(Puppet::Util::Execution).to receive(:execute).with(['sfboot', "'boot-image=uefi'", "'port-mode=[1x10/25g][1x10/25g]'",
                                                                   "'firmware-variant=ultra-low-latency'"]).and_return(fake_sfboot_output)

        expect(cli_helper.set_attrs(attrs)).to eq(sfboot_params)
      end
    end

    context 'with adapter specified' do
      let(:attrs) do
        {
          link_speed: '10g',
          boot_type: 'PXE',
          switch_mode: 'pfiov',
        }
      end

      it 'runs sfboot and parses its output correctly' do
        expect(Puppet::Util::Execution).to receive(:execute).with(['sfboot', '-i', 'enp196s0f1np1', "'link-speed=10g'", "'boot-type=PXE'", "'switch-mode=pfiov'"]).and_return(fake_sfboot_output)

        expect(cli_helper.set_attrs(attrs, 'enp196s0f1np1')).to eq(sfboot_params)
      end
    end
  end

  describe '#attr_to_cli' do
    [
      [:boot_image, 'all', 'boot-image=all'],
      [:boot_image, 'optionrom', 'boot-image=optionrom'],
      [:boot_image, 'uefi', 'boot-image=uefi'],
      [:boot_image, 'disabled', 'boot-image=disabled'],
      [:link_speed, 'auto', 'link-speed=auto'],
      [:link_speed, '10g', 'link-speed=10g'],
      [:link_speed, '1g', 'link-speed=1g'],
      [:link_speed, '100m', 'link-speed=100m'],
      [:linkup_delay, 5, 'linkup-delay=5'],
      [:linkup_delay, 255, 'linkup-delay=255'],
      [:banner_delay, 2, 'banner-delay=2'],
      [:banner_delay, 255, 'banner-delay=255'],
      [:bootskip_delay, 5, 'bootskip-delay=5'],
      [:bootskip_delay, 255, 'bootskip-delay=255'],
      [:boot_type, 'pxe', 'boot-type=pxe'],
      [:boot_type, 'disabled', 'boot-type=disabled'],
      [:pf_count, 1, 'pf-count=1'],
      [:msix_limit, 32, 'msix-limit=32'],
      [:vf_count, 0, 'vf-count=0'],
      [:vf_msix_limit, 8, 'vf-msix-limit=8'],
      [:port_mode, '[4x10/25g]', 'port-mode=[4x10/25g]'],
      [:port_mode, '[1x10/25g][1x10/25g]', 'port-mode=[1x10/25g][1x10/25g]'],
      [:firmware_variant, 'full-feature', 'firmware-variant=full-feature'],
      [:firmware_variant, 'ultra-low-latency', 'firmware-variant=ultra-low-latency'],
      [:firmware_variant, 'capture-packed-stream', 'firmware-variant=capture-packed-stream'],
      [:firmware_variant, 'dpdk', 'firmware-variant=dpdk'],
      [:firmware_variant, 'auto', 'firmware-variant=auto'],
      [:insecure_filters, 'default', 'insecure-filters=default'],
      [:insecure_filters, 'enabled', 'insecure-filters=enabled'],
      [:insecure_filters, 'disabled', 'insecure-filters=disabled'],
      [:mac_spoofing, 'default', 'mac-spoofing=default'],
      [:mac_spoofing, 'enabled', 'mac-spoofing=enabled'],
      [:mac_spoofing, 'disabled', 'mac-spoofing=disabled'],
      [:change_mac, 'default', 'change-mac=default'],
      [:change_mac, 'enabled', 'change-mac=enabled'],
      [:change_mac, 'disabled', 'change-mac=disabled'],
      [:pf_vlans, 'none', 'pf-vlans=none'],
      [:pf_vlans, [11, 12, 234], 'pf-vlans=11,12,234'],
      [:switch_mode, 'default', 'switch-mode=default'],
      [:switch_mode, 'sriov', 'switch-mode=sriov'],
      [:switch_mode, 'partitioning', 'switch-mode=partitioning'],
      [:switch_mode, 'partitioning-with-sriov', 'switch-mode=partitioning-with-sriov'],
      [:switch_mode, 'pfiov', 'switch-mode=pfiov'],
      [:rx_dc_size, 32, 'rx-dc-size=32'],
      [:tx_dc_size, 16, 'tx-dc-size=16'],
      [:vi_count, 2048, 'vi-count=2048'],
      [:event_merge_timeout, 1500, 'event-merge-timeout=1500'],
      [:event_merge_timeout, 'default', 'event-merge-timeout=default'],
    ].each do |t|
      specify do
        expect(cli_helper.attr_to_cli(t[0], t[1])).to eq("'#{t[2]}'")
      end
    end
  end

  describe '#output_to_attr' do
    [
      ['Boot image', :boot_image, 'Option ROM and UEFI', 'all'],
      ['Boot image', :boot_image, 'Option ROM only', 'optionrom'],
      ['Boot image', :boot_image, 'UEFI only', 'uefi'],
      ['Boot image', :boot_image, 'Disabled', 'disabled'],
      ['Link speed', :link_speed, 'Negotiated automatically', 'auto'],
      ['Link speed', :link_speed, '10G bits/second', '10g'],
      ['Link speed', :link_speed, '1G bits/second', '1g'],
      ['Link speed', :link_speed, '100m bits/second', '100m'],
      ['Link-up delay time', :linkup_delay, '5 seconds', 5],
      ['Link-up delay time', :linkup_delay, '255 seconds', 255],
      ['Banner delay time', :banner_delay, '2 seconds', 2],
      ['Banner delay time', :banner_delay, '255 seconds', 255],
      ['Boot skip delay time', :bootskip_delay, '5 seconds', 5],
      ['Boot skip delay time', :bootskip_delay, '255 seconds', 255],
      ['Boot type', :boot_type, 'PXE', 'pxe'],
      ['Boot type', :boot_type, 'Disabled', 'disabled'],
      ['Physical Functions on this port', :pf_count, '1', 1],
      ['PF MSI-X interrupt limit', :msix_limit, '32', 32],
      ['Virtual Functions on each PF', :vf_count, '0', 0],
      ['VF MSI-X interrupt limit', :vf_msix_limit, '8', 8],
      ['Port mode', :port_mode, '[4x10/25G]', '[4x10/25g]'],
      ['Port mode', :port_mode, '[1x10/25g][1x10/25G]', '[1x10/25g][1x10/25g]'],
      ['Firmware variant', :firmware_variant, 'Full feature / virtualization', 'full-feature'],
      ['Firmware variant', :firmware_variant, 'Ultra low latency', 'ultra-low-latency'],
      ['Firmware variant', :firmware_variant, 'Capture packed stream', 'capture-packed-stream'],
      ['Firmware variant', :firmware_variant, 'Data Plane Development Kit (DPDK)', 'dpdk'],
      ['Firmware variant', :firmware_variant, 'Auto', 'auto'],
      ['Insecure filters', :insecure_filters, 'Default', 'default'],
      ['Insecure filters', :insecure_filters, 'Enabled', 'enabled'],
      ['Insecure filters', :insecure_filters, 'Disabled', 'disabled'],
      ['MAC spoofing', :mac_spoofing, 'Default', 'default'],
      ['MAC spoofing', :mac_spoofing, 'Enabled', 'enabled'],
      ['MAC spoofing', :mac_spoofing, 'Disabled', 'disabled'],
      ['Change MAC', :change_mac, 'Default', 'default'],
      ['Change MAC', :change_mac, 'Enabled', 'enabled'],
      ['Change MAC', :change_mac, 'Disabled', 'disabled'],
      ['VLAN tags', :pf_vlans, 'None', 'none'],
      ['VLAN tags', :pf_vlans, '11,12,234', [11, 12, 234]],
      ['Switch mode', :switch_mode, 'Default', 'default'],
      ['Switch mode', :switch_mode, 'SR-IOV', 'sriov'],
      ['Switch mode', :switch_mode, 'Partitioning', 'partitioning'],
      ['Switch mode', :switch_mode, 'Partitioning with SR-IOV', 'partitioning-with-sriov'],
      ['Switch mode', :switch_mode, 'PFIOV', 'pfiov'],
      ['RX descriptor cache size', :rx_dc_size,  '32', 32],
      ['TX descriptor cache size', :tx_dc_size,  '16', 16],
      ['Total number of VIs', :vi_count, '2048', 2048],
      ['Event merge timeout', :event_merge_timeout, '1500 nanoseconds', 1500],
      ['Event merge timeout', :event_merge_timeout, 'Default', 'default'],
    ].each do |t|
      specify do
        expect(cli_helper.output_to_attr(t[0], t[2])).to eq([t[1], t[3]])
      end
    end
  end

  describe '#run' do
    it 'runs sfboot with proper args' do
      expect(Puppet::Util::Execution).to receive(:execute).with(['sfboot', '-i', 'enp196s0f1np1', "'boot-image=all'"]).and_return(fake_sfboot_output)

      cli_helper.run(['-i', 'enp196s0f1np1', "'boot-image=all'"])
    end
  end

  # Simulates fake sfboot output for 2 adapters
  # Partition map warning is real thing FYI
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
