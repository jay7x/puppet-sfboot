# frozen_string_literal: true

require_relative '../../../puppet_x/jay7x/sfboot/cli_helper'

# Implementation for the sfboot_global type using the Resource API.
class Puppet::Provider::SfbootGlobal::SfbootGlobal
  def initialize
    @sfboot_helper = PuppetX::Sfboot::CliHelper.new
  end

  def get(context)
    params = @sfboot_helper.read_params
    context.debug("parsed sfboot output: #{params}")

    v = params.values[0]

    [
      {
        name: 'global',
        boot_image: v[:boot_image],
        port_mode: v[:port_mode],
        firmware_variant: v[:firmware_variant],
        insecure_filters: v[:insecure_filters],
        mac_spoofing: v[:mac_spoofing],
        change_mac: v[:change_mac],
        rx_dc_size: v[:rx_dc_size],
        tx_dc_size: v[:tx_dc_size],
        vi_count: v[:vi_count],
        event_merge_timeout: v[:event_merge_timeout],
      },
    ]
  end

  def set(context, changes, noop: false) # rubocop:disable Lint/UnusedMethodArgument
    name = 'global'
    raise 'Only "global" title is allowed' unless changes[name]

    should = changes[name][:should]
    context.updating(name) do
      @sfboot_helper.set_attrs(should)
    end
  end
end
