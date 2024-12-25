# frozen_string_literal: true

require 'open3'
require 'scanf'

# Implementation for the sfboot type using the Resource API.
class Puppet::Provider::SfbootAdapter::SfbootAdapter
  def initialize
    # This maps sfboot output to the Puppet type attributes
    @desc2param = {
      'link speed' => 'link_speed'.to_sym,
      'link-up delay time' => 'linkup_delay'.to_sym,
      'banner delay time' => 'banner_delay'.to_sym,
      'boot skip delay time' => 'bootskip_delay'.to_sym,
      'boot type' => 'boot_type'.to_sym,
      'physical functions on this port' => 'pf_count'.to_sym,
      'pf msi-x interrupt limit' => 'msix_limit'.to_sym,
      'virtual functions on each pf' => 'vf_count'.to_sym,
      'vf msi-x interrupt limit' => 'vf_msix_limit'.to_sym,
      'vlan tags' => 'pf_vlans'.to_sym,
      'switch mode' => 'switch_mode'.to_sym,
    }

    @how_to_parse = {
      link_speed: {
        parser: 'lookup',
        lookup: {
          'negotiated automatically' => 'auto',
          '10g bits/second' => '10g',
          '1g bits/second' => '1g',
          '100m bits/second' => '100m',
        },
      },
      switch_mode: {
        parser: 'lookup',
        lookup: {
          'default' => 'default',
          'sr-iov' => 'sriov',
          'partitioning' => 'partitioning',
          'partitioning with sr-iov' => 'partitioning-with-sriov',
          'pfiov' => 'pfiov',
        },
      },
      linkup_delay: {
        parser: 'scanf',
        scanf: '%d seconds',
      },
      banner_delay: {
        parser: 'scanf',
        scanf: '%d seconds',
      },
      bootskip_delay: {
        parser: 'scanf',
        scanf: '%d seconds',
      },
      msix_limit: {
        parser: 'scanf',
        scanf: '%d',
      },
      vf_msix_limit: {
        parser: 'scanf',
        scanf: '%d',
      },
      pf_count: {
        parser: 'scanf',
        scanf: '%d',
      },
      vf_count: {
        parser: 'scanf',
        scanf: '%d',
      },
    }

    # This maps the Puppet type attributes to sfboot parameters
    @type2sfboot = {
      link_speed: 'link-speed',
      linkup_delay: 'linkup-delay',
      banner_delay: 'banner-delay',
      bootskip_delay: 'bootskip-delay',
      boot_type: 'boot-type',
      pf_count: 'pf-count',
      msix_limit: 'msix-limit',
      vf_count: 'vf-count',
      vf_msix_limit: 'vf-msix-limit',
      pf_vlans: 'pf-vlans',
      switch_mode: 'switch-mode',
    }
  end

  def get(context)
    out = run_sfboot
    # context.debug("sfboot output: #{out}")
    params = parse_sfboot_output(out)
    context.debug("parsed sfboot output: #{params}")

    params.map do |k, v|
      # pf-vlans special processing (comma-separated String -> Array[Integer])
      pf_vlans = if v[:pf_vlans].casecmp('none').zero?
                   v[:pf_vlans]
                 else
                   v[:pf_vlans].split(',').map(&:to_i)
                 end

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
        pf_vlans: pf_vlans,
      }
    end
  end

  def set(context, changes, noop: false) # rubocop:disable Lint/UnusedMethodArgument
    changes.each do |name, change|
      # is = change.key?(:is) ? change[:is] : (get(context) || []).find { |r| r[:adapter] == name }
      should = change[:should]

      # As we don't have ensure here, we can only update
      context.updating(name) do
        sf_params = should.filter { |k, _v| k != :adapter }.map do |k, v|
          sf_param = @type2sfboot[k]

          # pf-vlans special processing (Array[Integer] -> comma-separated String)
          sf_value = if v.is_a?(Array)
                       v.join(',')
                     else
                       v
                     end

          "'#{sf_param}=#{sf_value}'"
        end

        args = ['-i', should[:adapter]] + sf_params
        run_sfboot(args)
      end
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
