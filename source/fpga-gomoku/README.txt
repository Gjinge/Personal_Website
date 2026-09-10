FPGA Gomoku - Digital System Design project (VHDL)
Team: Zeng Dingyao, Han Yuzhou, Jin Wenyuan, Jinge Guo

Board    : Digilent Nexys 4 DDR (Xilinx Artix-7 xc7a100tcsg324-1)
Tool     : Vivado 2020.2
Top level: vga_ctrl

Contents
  src/            VHDL design sources
  constraints/    Pin and clock constraints (Nexys 4 DDR)
  ip/             .coe image data for the start-screen ROM (Block Memory Generator)
  reports/        Vivado utilization, timing and power reports for the routed design
  bitstream/      Generated bitstream (vga_ctrl.bit)
  project_3.xpr   Vivado project file

Notes
  Source comments were originally saved in GBK; the copies here are converted to UTF-8
  so they display correctly. The design logic is unchanged.
  The Block Memory Generator IP is not included; re-create it from ip/fmxxx_rgb444.coe
  when rebuilding the project from scratch.
