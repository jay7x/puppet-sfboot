# frozen_string_literal: true

require_relative '../../../puppet_x/jay7x/sfboot/cli_helper'

# Implementation for the sfboot type using the Resource API.
class Puppet::Provider::SfbootAdapter::SfbootAdapter
  def initialize
    @sfboot_helper = PuppetX::Sfboot::CliHelper.new
  end

  def get(context)
    params = @sfboot_helper.read_params
    context.debug("parsed sfboot output: #{params}")

    params.map do |k, v|
      {
        adapter: k,
        link_speed: v[:link_speed],
        linkup_delay: v[:linkup_delay],
        banner_delay: v[:banner_delay],
        bootskip_delay: v[:bootskip_delay],
        boot_type: v[:boot_type],
        switch_mode: v[:switch_mode],
        pf_count: v[:pf_count],
        msix_limit: v[:msix_limit],
        vf_count: v[:vf_count],
        vf_msix_limit: v[:vf_msix_limit],
        pf_vlans: v[:pf_vlans],
      }
    end
  end

  def set(context, changes, noop: false) # rubocop:disable Lint/UnusedMethodArgument
    changes.each do |name, change|
      should = change[:should]

      context.updating(name) do
        @sfboot_helper.set_attrs(should, should[:adapter])
      end
    end
  end
end
