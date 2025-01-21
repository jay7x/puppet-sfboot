# frozen_string_literal: true

require 'spec_helper'

describe 'sfboot' do
  on_supported_os.each do |os, facts|
    context "on #{os} with Facter #{facts[:facterversion]} and Puppet #{facts[:puppetversion]}" do
      let(:facts) do
        facts
      end

      context 'with default params' do
        it { is_expected.to compile }

        it do
          is_expected.to contain_sfboot_global('global')
            .with_boot_image(nil)
            .with_port_mode(nil)
            .with_firmware_variant(nil)
            .with_insecure_filters(nil)
            .with_mac_spoofing(nil)
            .with_rx_dc_size(nil)
            .with_change_mac(nil)
            .with_tx_dc_size(nil)
            .with_vi_count(nil)
            .with_event_merge_timeout(nil)
        end

        it { is_expected.to have_sfboot_adapter_resource_count(0) }
      end

      context 'with adapters specified' do
        let(:params) do
          {
            adapters: {
              enp123s0f0: {
                link_speed: '10g',
                linkup_delay: 10,
                banner_delay: 11,
                bootskip_delay: 12,
                boot_type: 'disabled',
                evt_cut_thru: 'default',
              },
              enp123s0f1: {
                pf_count: 4,
                msix_limit: 1024,
                vf_count: 2,
                vf_msix_limit: 4,
                pf_vlans: [0, 100, 110, 120],
                switch_mode: 'partitioning-with-sriov',
                evt_cut_thru: 'disabled',
              },
            },
          }
        end

        it do
          is_expected.to contain_sfboot_adapter('enp123s0f0')
            .with_link_speed('10g')
            .with_linkup_delay(10)
            .with_banner_delay(11)
            .with_bootskip_delay(12)
            .with_boot_type('disabled')
            .with_evt_cut_thru('default')
        end

        it do
          is_expected.to contain_sfboot_adapter('enp123s0f1')
            .with_pf_count(4)
            .with_msix_limit(1024)
            .with_vf_count(2)
            .with_vf_msix_limit(4)
            .with_pf_vlans([0, 100, 110, 120])
            .with_switch_mode('partitioning-with-sriov')
            .with_evt_cut_thru('disabled')
        end
      end
    end
  end
end
