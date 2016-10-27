# APS2 / TDM inter-module communications

VHDL source files for for inter-module communications over the SATA cables
connecting APS2 and TDM slices. The modules use the [Xilinx Ethernet 1G/2.5G
BASE-X PCS/PMA or
SGMI](https://www.xilinx.com/products/intellectual-property/do-di-gmiito1gbsxpcs.html)
in LVDS SGMII PHY mode for the PHY layer with a simple MAC framer on top.

## Clocking

Since there is no clock recovery we require a system wide clock reference
provided by a 10MHz refernece to both the TDM and APS2. This is then multiplied
up by two MMCM's to provide all the appropriate clocks. We have been unable to
maintain a link at full 1Gbps rate (1.25Gbps line rate; 125MHz byte clock) and
have to underclock to 720Mbps (900Mbps line rate; 90MHz byte clock).

## Testing

A VHDL testbench (`test/SATA_interconnect_tb.vhd`) provides a basic
demonstration and shows latency through the link. It takes 600-700us for the
link to synchronize in simulation.

In the top modules, the SATA interconnects are connected to TCP streams on port
0xbb4e. On the TDM side the TCP rx stream is broadcast to all SATA interfaces
but only SATA connect 0 rx is connected to TCP tx. There is a Julia script
(`test/test_comms.jl`) that sends and checks packets in both directions.

```julia
julia> test_comms(ip"192.168.2.200", ip"192.168.2.201", 10000)
Progress: 100%|█████████████████████████████████████████| Time: 0:00:22

julia>
```

## License

Mozilla Public License Version 2.0
