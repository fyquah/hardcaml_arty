This example has been tested on the Vivado 2018.2 and 2020.2. This has been
tested on the Arty A7 on my linux host machine.

You need to install vivado and djtgcfg to run these examples. See
a section below on some pointers on how to do this.

To compile this example, run the following command.

```bash
source path/to/xilinx/installation/Vivado/2018.2/settings64.sh
make outputs/hardcaml_arty_top.bit
djtgcfg prog --file outputs/harcaml_arty_top.bit -d Arty -i 0
```

Then marvel at blinking LEDS.

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

## Common Problems

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
