----------------------------------------------------------------------------------
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
-- 02111-1307, USA.
--
-- �1997-2010 - X Engineering Software Systems Corp. (www.xess.com)
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- SDRAM/RAM upload/download via JTAG.
-- See userinstr_jtag.vhd for details of operation.
--------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.CommonPckg.all;
use work.UserInstrJtagPckg.all;
use work.SdramCntlPckg.all;
use work.ClkgenPckg.all;

library UNISIM;
use UNISIM.VComponents.all;


entity ramintfc_jtag is
  generic(
    BASE_FREQ_G   : real    := 12.0;    -- base frequency in MHz
    CLK_MUL_G     : natural := 25;      -- multiplier for base frequency
    CLK_DIV_G     : natural := 3;       -- divider for base frequency
    PIPE_EN_G     : boolean := true;
    DATA_WIDTH_G  : natural := 16;      -- width of data
    HADDR_WIDTH_G : natural := 23;      -- host-side address width
    SADDR_WIDTH_G : natural := 12;      -- SDRAM address bus width
    NROWS_G       : natural := 4096;    -- number of rows in each SDRAM bank
    NCOLS_G       : natural := 512      -- number of words in each row
    );
  port(
    fpgaClk_i : in    std_logic;  -- main clock input from external clock source
    sdClk_o   : out   std_logic;        -- clock to SDRAM
    sdClkFb_i : in    std_logic;        -- SDRAM clock comes back in
    sdRas_bo  : out   std_logic;        -- SDRAM RAS
    sdCas_bo  : out   std_logic;        -- SDRAM CAS
    sdWe_bo   : out   std_logic;        -- SDRAM write-enable
    sdBs_o    : out   std_logic;        -- SDRAM bank-address
    sdAddr_o  : out   std_logic_vector(SADDR_WIDTH_G-1 downto 0);  -- SDRAM address bus
    sdData_io : inout std_logic_vector(DATA_WIDTH_G-1 downto 0)  -- data bus to/from SDRAM
    );
end entity;


architecture arch of ramintfc_jtag is

  constant FREQ_G : real := (BASE_FREQ_G * real(CLK_MUL_G)) / real(CLK_DIV_G);
  signal clk      : std_logic;

  -- signals to/from the JTAG BSCAN module
  signal bscan_drck   : std_logic;      -- JTAG clock from BSCAN module
  signal bscan_reset  : std_logic;      -- true when BSCAN module is reset
  signal bscan_sel    : std_logic;      -- true when BSCAN module selected
  signal bscan_shift  : std_logic;  -- true when TDI & TDO are shifting data
  signal bscan_update : std_logic;      -- BSCAN TAP is in update-dr state
  signal bscan_tdi    : std_logic;      -- data received on TDI pin
  signal bscan_tdo    : std_logic;      -- scan data sent to TDO pin

  -- signals to/from the SDRAM controller
  signal sdram_reset  : std_logic;      -- reset to SDRAM controller
  signal hrd          : std_logic;      -- host read enable
  signal hwr          : std_logic;      -- host write enable
  signal earlyOpBegun : std_logic;  -- true when current read/write has begun
  signal done         : std_logic;      -- true when current read/write is done
  signal hAddr        : std_logic_vector(HADDR_WIDTH_G-1 downto 0);  -- host address
  signal hDin         : std_logic_vector(DATA_WIDTH_G-1 downto 0);  -- data input from host
  signal hDOut        : std_logic_vector(DATA_WIDTH_G-1 downto 0);  -- host data output to host
  
begin

  -- Generate a 100 MHz clock from the 12 MHz input clock.
  u0 : ClkGen
    generic map (BASE_FREQ_G => BASE_FREQ_G, CLK_MUL_G => CLK_MUL_G, CLK_DIV_G => CLK_DIV_G)
    port map (I              => fpgaClk_i, O => sdClk_o);

  clk <= sdClkFb_i;  -- main clock is SDRAM clock fed back into FPGA

  -- Generate a reset signal for the SDRAM controller.  
  process(clk)
    constant reset_dly_c : natural                        := 10;
    variable rst_cntr    : natural range 0 to reset_dly_c := 0;
  begin
    if rising_edge(clk) then
      sdram_reset <= NO;
      if rst_cntr < reset_dly_c then
        sdram_reset <= YES;
        rst_cntr    := rst_cntr + 1;
      end if;
    end if;
  end process;

  -- Boundary-scan interface to FPGA JTAG port.
  u_bscan : BSCAN_SPARTAN3
    port map(
      DRCK1  => bscan_drck,             -- JTAG clock
      RESET  => bscan_reset,            -- true when JTAG TAP FSM is reset
      SEL1   => bscan_sel,  -- USER1 instruction enables execution of the RAM interface
      SHIFT  => bscan_shift,  -- true when JTAG TAP FSM is in the SHIFT-DR state
      TDI    => bscan_tdi,  -- data bits from the PC arrive through here
      UPDATE => bscan_update,
      TDO1   => bscan_tdo,  -- LSbit of the tdo register outputs onto TDO pin and to the PC
      TDO2   => '0'         -- not using this input, so just hold it low
      );

  -- JTAG interface
  u1 : UserInstrJtag
    generic map(
      FPGA_TYPE_G        => SPARTAN3_G,
      ENABLE_RAM_INTFC_G => true,
      DATA_WIDTH_G       => DATA_WIDTH_G,
      ADDR_WIDTH_G       => HADDR_WIDTH_G
      )
    port map(
      clk           => clk,
      bscan_drck    => bscan_drck,
      bscan_reset   => bscan_reset,
      bscan_sel     => bscan_sel,
      bscan_shift   => bscan_shift,
      bscan_update  => bscan_update,
      bscan_tdi     => bscan_tdi,
      bscan_tdo     => bscan_tdo,
      rd            => hrd,
      wr            => hwr,
      begun         => earlyOpBegun,
      done          => done,
      addr          => hAddr,
      din           => hDOut,
      dout          => hDIn,
      test_progress => "11",
      test_failed   => NO
      );

  -- SDRAM controller
  u2 : SdramCntl
    generic map(
      FREQ_G        => FREQ_G,
      IN_PHASE_G    => true,
      PIPE_EN_G     => PIPE_EN_G,
      MAX_NOP_G     => 10000,
      DATA_WIDTH_G  => DATA_WIDTH_G,
      NROWS_G       => NROWS_G,
      NCOLS_G       => NCOLS_G,
      HADDR_WIDTH_G => HADDR_WIDTH_G,
      SADDR_WIDTH_G => SADDR_WIDTH_G
      )
    port map(
      clk_i          => clk,  -- master clock from external clock source (unbuffered)
      lock_i         => YES,  -- no DLLs, so frequency is always locked
      rst_i          => sdram_reset,    -- reset
      rd_i           => hrd,  -- host-side SDRAM read control from memory tester
      wr_i           => hwr,  -- host-side SDRAM write control from memory tester
      earlyOpBegun_o => earlyOpBegun,  -- early indicator that memory operation has begun
      done_o         => done,  -- SDRAM memory read/write done indicator
      hostAddr_i     => hAddr,  -- host-side address from memory tester to SDRAM
      hostData_i     => hDIn,  -- test data pattern from memory tester to SDRAM
      sdramData_o    => hDOut,          -- SDRAM data output to memory tester
      sdRas_bo       => sdRas_bo,       -- SDRAM RAS
      sdCas_bo       => sdCas_bo,       -- SDRAM CAS
      sdWe_bo        => sdWe_bo,        -- SDRAM write-enable
      sdBs_o(0)      => sdBs_o,         -- SDRAM bank address
      sdAddr_o       => sdAddr_o,       -- SDRAM address
      sdData_io      => sdData_io       -- data to/from SDRAM
      );

end architecture;
