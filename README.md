# Hardcaml Arty

A library to use [Digilent Arty A7 Boards](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/start) with [Hardcaml](https://github.com/janestreet/hardcaml).

This library has been tested with Arty A7 35 and Arty A7 100.

## Features

This library provides a wrapper for the following features in Arty A7 boards:

- A 166.66667MHz clock and its corresponding synchronous active low clear.
- A 200MHz clock and its corresponding synchronous active low clear.
- Control bits (on/off) for the board's LEDs.
- Control bits (on/off for r, g, and b) for the board's RGB LEDs.
- UART receive and transmit data streams.
- Ethernet receive and transmit data streams.

## Setup

This section describes what you'll need to add to an existing Hardcaml design in order to turn it into a bitstream that can run on an Arty A7 board.

See [examples/blinker](examples/blinker) for an example, reference files to copy into your own project, and instructions on how to:

- Install some necessary programs/utilities.
- Generate the bitstream.
- Load it onto your board.

### Board Metadata

Copy the `boards` folder from [examples/blinker](examples/blinker) into the top-level directory of your project.

This tells Vivado which board to use when compiling your design, provides some configuration for said board, and sets human-readable names for the board's pins that will be used later on in the constraint files.

### IPs

Copy the `ips` folder from [examples/blinker](examples/blinker) into the top-level directory of your project.

This library makes use of several Xilinx IPs:

- The clocking wizard, used for generating aforementioned clock/clear signals from the board's system clock ([Manual](https://www.xilinx.com/support/documentation/ip_documentation/clk_wiz/v6_0/pg065-clk-wiz.pdf)).
- The Tri-Mode Ethernet MAC, used for supporting Ethernet communication ([Manual](https://www.xilinx.com/support/documentation/ip_documentation/tri_mode_ethernet_mac/v9_0/pg051-tri-mode-eth-mac.pdf)).

Please note that while the clocking wizard is provided alongside Vivado software installation, the ethernet MAC requires a special license. See the [examples/blinker README](examples/blinker) for more information.

### RTL Generation Executable

Essentially, this library works by taking a Hardcaml subcircuit that contains your design, and wrapping to abstract away some messy infrastructure / IP interaction so you can work with a clean, simple API.
This means you will need to give it a subcircuit that implements the [`User_application.I` and `User_application.O`](https://github.com/fyquah/hardcaml_arty/blob/master/src/infrastructure/user_application.mli) [Hardcaml interfaces](https://github.com/janestreet/hardcaml/blob/master/docs/module_hierarchy.mdx#a-design-pattern-for-circuits). Once you have that, you can use this library's `Rtl_generator.generate` function to generate Arty A7-compatible Verilog output.

We recommmend creating an `arty.ml` file (with the corresponding `dune` config to make it an executable) in the top-level directory of your project that defines a `create` function which wraps your design to input/output the aforementioned `User_application` interfaces, then define a main function:

```
let () =
  Hardcaml_arty.Rtl_generator.generate create (To_channel Stdio.stdout)
;;
```

### Constraint Files

Copy the `place.tcl`, `route.tcl`, `synth.tcl`, and `Makefile` files from [examples/blinker) into the top-level directory of your project.

These files instruct Vivado to generate the bitstream for your design:

- `synth.tcl` synthesizes your design into a netlist, including the aforementioned IPs.
- `place.tcl` binds the input and output ports used by this library's wrapper module to pins on the board, and runs implementation.
- `route.tcl` generates the bitstream.

The `Makefile` links these build steps together. You'll need to adjust it slightly for the RTL generation executable you made in the previous step (e.g. replacing "blinker" with "arty").
The `Makefile` requires a `BOARD` env variable parameter which can be either `arty-a7-35` or `arty-a7-100`.

### How to Run

Now, all that's left is to actually generate a bitstream and load it onto your board! Follow the instructions at [examples/blinker](examples/blinker), adapting to your project's directory structure.

## Board Tools Reference

This section is a summary of the tools offered by this library to interact with some of the less trivial Arty A7 components, notably UART and Ethernet.

### UART

UART input/output data streams are encoded as a [Hardcaml With_valid](https://ocaml.janestreet.com/ocaml-core/v0.13/doc/hardcaml/Hardcaml/With_valid/index.html) record, which has `value` and `valid` fields.
`value` is an 8-bit wire that represents the last 8 received UART data bits, with the MSB corresponding to the most recently received bit.
`valid` becomes `1` when every 8th UART bit is received; that is, when every byte has been completely received.

The UART uses the 166.66667MHz clock signal and corresponding clear, and processes one bit every `166_667_000 / 115_200 = 1446` cycles.

### Ethernet

