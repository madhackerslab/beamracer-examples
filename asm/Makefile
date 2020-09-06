CA65   = ca65
CL65   = cl65
LD65   = ld65

BINDIR = bin

DEMOS = $(BINDIR)/demorb1 \
	    $(BINDIR)/logo $(BINDIR)/irq \
		$(BINDIR)/fld

all: $(DEMOS) $(EXAMPLES)

VLIB = vlib/vasyl.s vlib/vlib.s

$(BINDIR)/demorb1: demo_rasterbars_cpu.s sinus_ntsc.inc $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/irq: demo_irq.s  $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/logo: demo_logo.s logo_dlist.inc $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

$(BINDIR)/fld: demo_fld.s  $(VLIB)
	$(CL65) -t c64 -C c64-asm.cfg -u __EXEHDR__ $< -o $@

clean:
	rm -f *.o 
