This example has been tested on the Vivado 2018.2 and 2020.2. This has been
tested on the Arty A7 on my linux host machine.

You need to install vivado and djtgcfg to run these examples. You will also need to obtain a license from Xilinx to use the ethernet component. See
a section below on some pointers on how to do this.

To compile this example, run the following command.

```bash
source path/to/xilinx/installation/Vivado/2018.2/settings64.sh
BOARD=arty-a7-35 make outputs/hardcaml_arty_top.bit
djtgcfg prog --file outputs/hardcaml_arty_top.bit -d Arty -i 0
```

Then marvel at blinking LEDS.

This example does three things (independently), mostly to try to demonstrate
how some nice examples can be written with hardcaml.

- Cycle through the 4 LEDS. One cycle is around 4 seconds
- Cycle through the 12 RGB LEDs. One cycle is around 4 seconds
- Uart loopback with a `115\_200` baud rate. To try this out, run `picocom -b
  115200 /dev/ttyUSB1` (You might need to replace ttyUSB1 with something
  different)

## Setting Up Vivado

Install vivado [here](https://www.xilinx.com/support/download.html) , you
will need to agree to the vivado terms and conditions.

I had trouble installing vivado with my Vivado 2020.1,
[this link solved my problem](https://forums.xilinx.com/t5/Installation-and-Licensing/Installation-of-Vivado-2020-1-under-Centos-7-8-fails/td-p/1115482), pointing out some java GUI related issues.

## Setting Up djtagcfg and Drivers

Firstly install the digilent drivers

```bash
cd path/to/Vivado/2018.2/data/xicom/cable_drivers/lin64/install_script/install_drivers
./install_digilent.sh
```

Then install digilent adept 2 utilities, which can be downloaded
[here](https://store.digilentinc.com/digilent-adept-2-download-only/). This should
provide the `djtagcfg` to write an FPGA bitstream via jtag.

## Obtaining a License for the Ethernet MAC

See [this website](https://ethernetfmc.com/getting-a-license-for-the-xilinx-tri-mode-ethernet-mac/) for a guide.

## (Anticipated) Common Problems

1. **ERROR: failed to initialize scan chain**

First, check if your board exist, using `djtgcfg enum`. This was my output:

```
Found 1 device(s)

  Device: Arty
  Product Name:   Digilent Arty
  User Name:      Arty
  Serial Number:  XXXXXXXXXXXX
```

Then, make sure the `djtgcfg prog` is correct. Specifically, it is "Arty",
_not "arty"_.

2. **The UART loopback just freezes on me sometimes.**

First try the following

- Flash the FPGA firmware with `djtgcfg`  again
- Hit the reset button on the FPGA
- Plug it and unplug it
- Try a (few) different USB cable

Then, if all fails, submit an issue
