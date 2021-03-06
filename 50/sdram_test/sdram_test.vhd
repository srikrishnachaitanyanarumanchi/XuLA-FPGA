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
-- Simple SDRAM test with result output on channel I/O pins.
--------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.CommonPckg.all;
use work.TestBoardCorePckg.all;
use work.ClkgenPckg.all;

library UNISIM;
use UNISIM.VComponents.all;

entity sdram_test is
  generic(
    BASE_FREQ_G   : real    := 12.0;      -- base frequency in MHz
    CLK_MUL_G     : natural := 25;        -- multiplier for base frequency
    CLK_DIV_G     : natural := 3;         -- divider for base frequency
    PIPE_EN_G     : boolean := true;
    DATA_WIDTH_G  : natural := 16;        -- width of data
    HADDR_WIDTH_G : natural := 23;        -- host-side address width
    SADDR_WIDTH_G : natural := 12;        -- SDRAM address bus width
    NROWS_G       : natural := 4096;      -- number of rows in each SDRAM bank
    NCOLS_G       : natural := 512;       -- number of words in each row
    -- beginning and ending addresses for the entire SDRAM
    BEG_ADDR_G    : natural := 16#00_0000#;
    END_ADDR_G    : natural := 16#7F_FFFF#;
    -- beginning and ending address for the memory tester
    BEG_TEST_G    : natural := 16#00_0000#;
    END_TEST_G    : natural := 16#3F_FFFF#
    );
  port(
    fpgaClk_i     : in    std_logic;  -- main clock input from external clock source
    sdClk_o    : out   std_logic;     -- clock to SDRAM
    sdClkFb_i : in    std_logic;     -- SDRAM clock comes back in
    sdRas_bo        : out   std_logic;     -- SDRAM RAS
    sdCas_bo        : out   std_logic;     -- SDRAM CAS
    sdWe_bo         : out   std_logic;     -- SDRAM write-enable
    sdBs_o           : out   std_logic;     -- SDRAM bank-address
    sdAddr_o            : out   std_logic_vector(SADDR_WIDTH_G-1 downto 0);  -- SDRAM address bus
    sdData_io            : inout std_logic_vector(DATA_WIDTH_G-1 downto 0);  -- data bus to/from SDRAM
    chan_io         : inout std_logic_vector(5 downto 1)
    );
end sdram_test;


architecture arch of sdram_test is

  constant FREQ_G        : real := (BASE_FREQ_G * real(CLK_MUL_G)) / real(CLK_DIV_G);
  signal clk             : std_logic;

begin

  u0 : Clkgen
    generic map (BASE_FREQ_G => BASE_FREQ_G, CLK_MUL_G => CLK_MUL_G, CLK_DIV_G => CLK_DIV_G)
    port map(I             => fpgaClk_i, O => sdClk_o);

  clk <= sdClkFb_i;  -- main clock is SDRAM clock fed back into FPGA

  -- board diagnostic unit
  u1 : TestBoardCore
    generic map(
      FREQ_G        => FREQ_G,
      PIPE_EN_G     => PIPE_EN_G,
      DATA_WIDTH_G  => DATA_WIDTH_G,
      SADDR_WIDTH_G => SADDR_WIDTH_G,
      NROWS_G       => NROWS_G,
      NCOLS_G       => NCOLS_G,
      BEG_ADDR_G    => BEG_ADDR_G,
      END_ADDR_G    => END_ADDR_G,
      BEG_TEST_G    => BEG_TEST_G,
      END_TEST_G    => END_TEST_G
      )
    port map(
      clk_i       => clk,
      sdRas_bo     => sdRas_bo,
      sdCas_bo     => sdCas_bo,
      sdWe_bo      => sdWe_bo,
      sdBs_o(0)     => sdBs_o,
      sdAddr_o     => sdAddr_o,
      sdData_io     => sdData_io,
      heartBeat_o => chan_io(1), -- Indicates if the test is running or not.
      err_o       => chan_io(3), -- Indicates if the test passed or not.
      progress_o  => chan_io(5 downto 4) -- Indicates the phase of the test in progress.
      );

end architecture;

