FPGA_PART     := xc3s50a-4-vq100
fpga_projects := test_board_jtag ramintfc_jtag fintf_jtag fjmem_intfc counter

export XST_FPGA_OPTIONS_FILE ?= $(CURDIR)/../xst_fpga_options.xst
export BITGEN_OPTIONS_FILE   ?= $(CURDIR)/bitgen_options.ut
export UCF_FILE              ?= $(CURDIR)/../XuLA_LIB/XuLA-50.ucf

.PHONY: $(fpga_projects:=.config) \
        $(fpga_projects:=.exo) \
        $(fpga_projects:=.timing) \
        $(fpga_projects:=.clean) \
        $(fpga_projects:=.distclean) \
        $(fpga_projects:=.maintainer-clean) \
        $(fpga_projects:=.nice)

config          : $(fpga_projects:=.config)           
exo             : $(fpga_projects:=.exo)
timing          : $(fpga_projects:=.timing)
clean           : $(fpga_projects:=.clean)            
distclean       : $(fpga_projects:=.distclean)        
maintainer-clean: $(fpga_projects:=.maintainer-clean) 
nice            : $(fpga_projects:=.nice)             

$(fpga_projects:=.config):
	$(MAKE) -C $(subst .config,,$@) PART=$(FPGA_PART) $@

$(fpga_projects:=.exo):
	$(MAKE) -C $(subst .exo,,$@) PART=$(FPGA_PART) $@

$(fpga_projects:=.timing):
	$(MAKE) -C $(subst .timing,,$@) PART=$(FPGA_PART) $@

$(fpga_projects:=.clean) $(cpld_projects:=.clean):
	$(MAKE) -C $(subst .clean,,$@) $@

$(fpga_projects:=.distclean) $(cpld_projects:=.distclean):
	$(MAKE) -C $(subst .distclean,,$@) $@

$(fpga_projects:=.maintainer-clean) $(cpld_projects:=.maintainer-clean):
	$(MAKE) -C $(subst .maintainer-clean,,$@) $@

$(fpga_projects:=.nice) $(cpld_projects:=.nice):
	$(MAKE) -C $(subst .nice,,$@) $@
