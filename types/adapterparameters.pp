# @summary This type describes Solarflare per-adapter Boot Rom parameters
#
# See `sfboot_adapter` resource type description for more information on fields.
#
type Sfboot::AdapterParameters = Struct[{
    link_speed => Optional[Enum['auto','10g','1g','100m']],
    linkup_delay => Optional[Integer[0,255]],
    banner_delay => Optional[Integer[0,255]],
    bootskip_delay => Optional[Integer[0,255]],
    boot_type => Optional[Enum['pxe','disabled']],
    pf_count => Optional[Integer[0]],
    msix_limit => Optional[Variant[Integer[8,8], Integer[16,16], Integer[32,32], Integer[64,64], Integer[128,128], Integer[256,256], Integer[512,512], Integer[1024,1024]]],
    vf_count => Optional[Integer[0]],
    vf_msix_limit => Optional[Variant[Integer[1,2], Integer[4,4], Integer[8,8], Integer[16,16], Integer[32,32], Integer[64,64], Integer[128,128], Integer[256,256]]],
    pf_vlans => Optional[Variant[Enum['none'], Array[Integer[0,4094]]]],
    switch_mode => Optional[Enum['default','sriov','partitioning','partitioning-with-sriov','pfiov']],
}]
