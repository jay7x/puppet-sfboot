# frozen_string_literal: true

require 'puppet_x'
require 'puppet'
require 'scanf'

module PuppetX::Sfboot
  # Sfboot Error type
  class Error < StandardError; end

  # Helper functions for parsing sfboot tool output
  class CliHelper
    def initialize
      # How to parse a raw sfboot output to the type attribute
      @output_to_attr = {
        ## Global params
        'boot image' => {
          name: :boot_image,
          parser: 'lookup',
          lookup: {
            'option rom and uefi' => 'all',
            'option rom only' => 'optionrom',
            'uefi only' => 'uefi',
            'disabled' => 'disabled',
          },
        },
        'port mode' => { name: :port_mode },
        'firmware variant' => {
          name: :firmware_variant,
          parser: 'lookup',
          lookup: {
            'full feature / virtualization' => 'full-feature',
            'ultra low latency' => 'ultra-low-latency',
            'capture packed stream' => 'capture-packed-stream',
            'data plane development kit (dpdk)' => 'dpdk',
            'auto' => 'auto',
          },
        },
        'insecure filters' => { name: :insecure_filters },
        'mac spoofing' => { name: :mac_spoofing },
        'change mac' => { name: :change_mac },
        'rx descriptor cache size' => {
          name: :rx_dc_size,
          parser: 'int',
        },
        'tx descriptor cache size' => {
          name: :tx_dc_size,
          parser: 'int',
        },
        'total number of vis' => {
          name: :vi_count,
          parser: 'int',
        },
        'event merge timeout' => {
          name: :event_merge_timeout,
          parser: 'scanf',
          scanf: '%d nanoseconds',
        },
        ## Per-adapter params
        'link speed' => {
          name: :link_speed,
          parser: 'lookup',
          lookup: {
            'negotiated automatically' => 'auto',
            '10g bits/second' => '10g',
            '1g bits/second' => '1g',
            '100m bits/second' => '100m',
          },
        },
        'link-up delay time' => {
          name: :linkup_delay,
          parser: 'scanf',
          scanf: '%d seconds',
        },
        'banner delay time' => {
          name: :banner_delay,
          parser: 'scanf',
          scanf: '%d seconds',
        },
        'boot skip delay time' => {
          name: :bootskip_delay,
          parser: 'scanf',
          scanf: '%d seconds',
        },
        'boot type' => { name: :boot_type },
        'physical functions on this port' => {
          name: :pf_count,
          parser: 'int',
        },
        'pf msi-x interrupt limit' => {
          name: :msix_limit,
          parser: 'int',
        },
        'virtual functions on each pf' => {
          name: :vf_count,
          parser: 'int',
        },
        'vf msi-x interrupt limit' => {
          name: :vf_msix_limit,
          parser: 'int',
        },
        'vlan tags' => {
          name: :pf_vlans,
          parser: 'proc',
          # Convert "11,12" String to [11,12] Array
          proc: proc { |x| x.casecmp('none').zero? ? 'none' : x.split(',').map(&:to_i) }
        },
        'switch mode' => {
          name: :switch_mode,
          parser: 'lookup',
          lookup: {
            'default' => 'default',
            'sr-iov' => 'sriov',
            'partitioning' => 'partitioning',
            'partitioning with sr-iov' => 'partitioning-with-sriov',
            'pfiov' => 'pfiov',
          },
        },
      }

      # How to map a type attribute name & value to the CLI option
      @attr_to_cli = {
        # Global params
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
        # Per-adapter params
        link_speed: 'link-speed',
        linkup_delay: 'linkup-delay',
        banner_delay: 'banner-delay',
        bootskip_delay: 'bootskip-delay',
        boot_type: 'boot-type',
        pf_count: 'pf-count',
        msix_limit: 'msix-limit',
        vf_count: 'vf-count',
        vf_msix_limit: 'vf-msix-limit',
        pf_vlans: {
          name: 'pf-vlans',
          parser: 'proc',
          proc: proc { |x| Array(x).join(',') }
        },
        switch_mode: 'switch-mode',
      }
    end

    # Run sfboot and return its output parsed
    def read_params
      parse_sfboot_output(run)
    end

    # Run sfboot with attrs specified and return its output parsed
    #
    # @param Hash[String, Any] attrs
    #   Hash of attributes
    # @param Optional[String] adapter
    #   NIC name to apply the changes to
    def set_attrs(attrs, adapter = nil)
      options = attrs.map do |k, v|
        attr_to_cli(k, v)
      end

      args = []
      args << '-i' << adapter if adapter
      args += options

      parse_sfboot_output(run(args))
    end

    # Convert the (resource type attribute name, value) pair to the sfboot CLI option
    # Return nil if attribute name is unknown
    def attr_to_cli(attr_name, attr_value)
      return nil unless @attr_to_cli.key? attr_name

      pi = @attr_to_cli[attr_name]
      parser_info = pi.is_a?(Hash) ? pi : { name: pi }
      param = parser_info[:name]

      value = case parser_info.fetch(:parser, 'default')
              when 'proc'
                parser_info[:proc].call(attr_value)
              else
                attr_value
              end

      "'#{param}=#{value}'"
    end

    # Convert raw sfboot output (param name, value text) pair to the resource
    # (attribute name, value) pair
    def output_to_attr(k, v)
      raw_param = k.strip.downcase
      raw_value = v.strip.downcase
      return [nil, nil] unless @output_to_attr.key? raw_param

      parser_info = @output_to_attr[raw_param]
      param = parser_info[:name]

      value = case parser_info.fetch(:parser, 'default')
              when 'int'
                Integer(raw_value)
              when 'scanf'
                raw_value.scanf(parser_info[:scanf])[0]
              when 'lookup'
                parser_info[:lookup][raw_value]
              when 'proc'
                parser_info[:proc].call(raw_value)
              else
                raw_value
              end

      [param, value]
    end

    # Run sfboot with the parameters specified
    # Undefined args are removed
    def run(args = [])
      cmd = ['sfboot'] + args.filter { |x| !x.nil? }
      Puppet::Util::Execution.execute(cmd)
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
          (k, v) = output_to_attr(*ss.captures)
          pairs[k] = v if k
        end
        nps[nic] = pairs
      end

      nps
    end
  end
end
