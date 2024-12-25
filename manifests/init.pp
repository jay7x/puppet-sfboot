# @summary
#   Manage Solarflare Boot ROM parameters
#
# @param boot_image
#   Specifies which boot firmware images are served-up to the BIOS during
#   start-up.
#
# @param port_mode
#   Configure the port mode to use.
#
# @param firmware_variant
#   Configure the firmware variant to use.
#
# @param insecure_filters
#   Grant or revoke a privilege to bypass on filter security for non-privileged
#   functions on this port.
#
# @param mac_spoofing
#   If enabled, non-privileged functions can create unicast filters for MAC
#   addresses that are not associated with them.
#
# @param rx_dc_size
#   Specifies the size of the descriptor cache for each receive queue.
#
# @param change_mac
#   Change the unicast MAC address for a non-privileged function on this port.
#
# @param tx_dc_size
#   Specifies the size of the descriptor cache for each transmit queue.
#
# @param vi_count
#   Sets the total number of virtual interfaces that will be available on the
#   NIC.
#
# @param event_merge_timeout
#   Specifies the timeout (in nanoseconds) for RX event merging.
#
# @param adapters
#   Hash of adapters and their Boot ROM parameters. This allows to manage
#   per-adapter parameters via Hiera.
#
class sfboot (
  Optional[Enum['all','optionrom','uefi','disabled']] $boot_image = undef,
  Optional[Variant[Enum['default'], String[1]]] $port_mode = undef,
  Optional[Enum['full-feature','ultra-low-latency','capture-packed-stream','dpdk','auto']] $firmware_variant = undef,
  Optional[Enum['default','enabled','disabled']] $insecure_filters = undef,
  Optional[Enum['default','enabled','disabled']] $mac_spoofing = undef,
  Optional[Variant[Integer[8,8], Integer[16,16], Integer[32,32], Integer[64,64]]] $rx_dc_size = undef,
  Optional[Enum['default','enabled','disabled']] $change_mac = undef,
  Optional[Variant[Integer[8,8], Integer[16,16], Integer[32,32], Integer[64,64]]] $tx_dc_size = undef,
  Optional[Integer[0]] $vi_count = undef,
  Optional[Integer[0]] $event_merge_timeout = undef,
  Hash[String[1], Sfboot::AdapterParameters] $adapters = {},
) {
  sfboot_global { 'global':
    boot_image          => $boot_image,
    port_mode           => $port_mode,
    firmware_variant    => $firmware_variant,
    insecure_filters    => $insecure_filters,
    mac_spoofing        => $mac_spoofing,
    rx_dc_size          => $rx_dc_size,
    change_mac          => $change_mac,
    tx_dc_size          => $tx_dc_size,
    vi_count            => $vi_count,
    event_merge_timeout => $event_merge_timeout,
  }

  $adapters.each |$adapter, $params| {
    sfboot_adapter { $adapter:
      * => $params,
    }
  }
}
