XuLA-50 Board Design Projects
    Each of these directories contains a complete Xilinx ISE WebPACK 13
    design project.

    * counter
        A simple 26-bit counter that is driven by a 100 MHz clock and whose
        bits are output throuogh the prototyping header. This is a good
        design to check the functioning of the XuLA board. *Check the
        setting for the startup-clock - either JTAGCLK or CCLK - to make
        sure it complies with how you are using the XuLA board - either
        USB-connected or standalone.*

    * fintf_jtag
        This design is used by GXSLOAD when it needs to read or write the
        contents of the serial flash configuration memory on the XuLA board.

    * fjmem_intfc
        This design is used to interface the XuLA board to the UrJtag tools.
        It is not yet ready for general release, so it is currently not
        supported.

    * logic_analyzer
        This is a version of the Sump logic analyzer for the XuLA board. It
        is not yet completely functional.

    * ramintfc_jtag
        This design is used by GXSLOAD when it needs to read or write the
        contents of the SDRAM on the XuLA board.

    * sdram_test
        This design is a simple tester for the SDRAM that reports success or
        failure through the prototyping header rather than sending the
        status through the JTAG and USB links.

    * test_board_jtag
        This design is used by GXSTEST to test the SDRAM and report the
        success or failure through the JTAG and USB links.

