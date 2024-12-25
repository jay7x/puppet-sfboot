# frozen_string_literal: true

require 'open3'
require 'scanf'

# Implementation for the sfboot_global type using the Resource API.
class Puppet::Provider::SfbootGlobal::SfbootGlobal
  def initialize
    # This maps sfboot output to the Puppet type attributes
    @desc2param = {
      'boot image' => 'boot_image'.to_sym,
      'port mode' => 'port_mode'.to_sym,
      'firmware variant' => 'firmware_variant'.to_sym,
      'insecure filters' => 'insecure_filters'.to_sym,
      'mac spoofing' => 'mac_spoofing'.to_sym,
      'change mac' => 'change_mac'.to_sym,
      'rx descriptor cache size' => 'rx_dc_size'.to_sym,
      'tx descriptor cache size' => 'tx_dc_size'.to_sym,
      'total number of vis' => 'vi_count'.to_sym,
      'event merge timeout' => 'event_merge_timeout'.to_sym,
    }

    @how_to_parse = {
      boot_image: {
        parser: 'lookup',
        lookup: {
          'option rom and uefi' => 'all',
          'option rom only' => 'optionrom',
          'uefi only' => 'uefi',
          'disabled' => 'disabled',
        },
      },
      firmware_variant: {
        parser: 'lookup',
        lookup: {
          'full feature / virtualization' => 'full-feature',
          'ultra low latency' => 'ultra-low-latency',
          'capture packed stream' => 'capture-packed-stream',
          'data plane development kit (dpdk)' => 'dpdk',
          'auto' => 'auto',
        },
      },
      event_merge_timeout: {
        parser: 'scanf',
        scanf: '%d nanoseconds',
      },
      rx_dc_size: {
        parser: 'scanf',
        scanf: '%d',
      },
      tx_dc_size: {
        parser: 'scanf',
        scanf: '%d',
      },
      vi_count: {
        parser: 'scanf',
        scanf: '%d',
      },
    }

    # This maps the Puppet type attributes to sfboot parameters
    @type2sfboot = {
      boot_image: 'boot-image',
      port_mode: 'port-mode',
      firmware_variant: 'firmware-variant',
      insecure_filters: 'insecure-filters',
      mac_spoofing: 'mac-spoofing',
      change_mac: 'change-mac',
      rx_dc_size: 'rx-dc-size',
      tx_dc_size: 'tx-dc-size',
      vi_count: 'vi-count',
      event_merge_timeout: 'event-merge-timeout',
    }
  end

  def get(context)
    out = run_sfboot
    params = parse_sfboot_output(out)
    context.debug("parsed sfboot output: #{params}")

    [
      params.values[0].merge(name: 'global'),
    ]
  end

  def set(context, changes, noop: false) # rubocop:disable Lint/UnusedMethodArgument
    name = 'global'
    raise 'Only "global" title is allowed' unless changes[name]

    should = changes[name][:should]
    context.updating(name) do
      sf_params = should.filter { |k, _v| k != :name }.map do |k, v|
        sf_param = @type2sfboot[k]
        sf_value = v

        "'#{sf_param}=#{sf_value}'"
      end

      run_sfboot(sf_params)
    end
  end

  private

  def parse_sfboot_output(output)
    ss = StringScanner.new(output)
    nps = {}
    # Look for nic name
    while ss.scan_until(%r{^(?![0-9])([a-z][a-z0-9_-]{1,14}):$})
      nic = ss.captures[0]
      pairs = {}
      # Loop collecting parameter and value pairs
      while ss.scan(%r{^\s+(.+?)  {2,}(.+)$})
        (k, v) = parse_params(*ss.captures)
        pairs[k] = v if k
      end
      nps[nic] = pairs
    end

    nps
  end

  def parse_params(k, v)
    pk = k.strip.downcase
    return [nil, nil] unless @desc2param.key? pk

    pn = @desc2param[pk]
    pv = v.strip.downcase
    # Check how to convert the value from sfboot output to input-able one
    # Default parser is `scanf('%s')` => just return the downcased string
    parser_info = @how_to_parse.fetch(pn, {})

    value = case parser_info.fetch(:parser, 'default')
            when 'scanf'
              fmt = parser_info[:scanf]
              pv.scanf(fmt)[0]
            when 'lookup'
              dict = parser_info[:lookup]
              dict[pv]
            else
              pv
            end

    [pn, value]
  end

  def run_sfboot(args = [])
    cmd = ['sfboot'] + args
    Puppet::Util::Execution.execute(cmd)
  end
end
