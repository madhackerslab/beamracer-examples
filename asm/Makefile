CA65   = ca65
CL65   = cl65
LD65   = ld65

BINDIR = bin

DEMOS = $(BINDIR)/demorb1.prg $(BINDIR)/demorb2.prg \
		$(BINDIR)/demorb3.prg \
	    $(BINDIR)/logo.prg $(BINDIR)/irq.prg \
		$(BINDIR)/fld.prg $(BINDIR)/fli.prg \
		$(BINDIR)/selfmod.prg $(BINDIR)/seq.prg \
		$(BINDIR)/irq2.prg \
		$(BINDIR)/hirestext.prg

all: $(DEMOS) $(EXAMPLES)

VLIB = vlib/vasyl.s vlib/vlib.s

$(BINDIR)/demorb1.prg: demo_rasterbars_cpu.s sinus_ntsc.inc $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/demorb2.prg: demo_rasterbars.s sinus_ntsc2.inc $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/demorb3.prg: demo_rastersplit.s sinus_ntsc2.inc $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/irq.prg: demo_irq.s  $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/irq2.prg: demo_irq2.s  $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/logo.prg: demo_logo.s logo_dlist.inc $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/fld.prg: demo_fld.s  $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/fli.prg: demo_fli.s  $(VLIB) image.fli
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/selfmod.prg: demo_selfmod.s $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/seq.prg: demo_seq.s $(VLIB) mhl.xbm
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/hirestext.prg: demo_hirestext.s $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

clean:
	rm -f *.o 
