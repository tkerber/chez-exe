
.PHONY: clean cleanconfig uninstall

-include make.in

fcs = full-chez.boot
pcs = petite-chez.boot

incdir ?= $(bootpath)
libdir ?= $(bootpath)

psboot = $(bootpath)/petite.boot
csboot = $(bootpath)/scheme.boot
custom_boot = custom-boot.ss
kernel = $(libdir)/libkernel.a
scheme ?= scheme
liblz4 = $(libdir)/liblz4.a
libz = $(libdir)/libz.a
main = $(libdir)/main.o

runscheme = "$(scheme)" -b "$(bootpath)/petite.boot" -b "$(bootpath)/scheme.boot"

compile-chez-program: compile-chez-program.ss full-chez.a petite-chez.a $(wildcard config.ss)
	$(runscheme) --compile-imported-libraries --program $< --full-chez --chez-lib-dir . $<

%.a: %_boot.o embed_target.o setup.o stubs.o main.o $(kernel) $(liblz4) $(libz)
	echo -e 'create $@\naddmod $<\naddmod embed_target.o\naddmod setup.o\naddmod stubs.o\naddmod main.o\naddlib $(kernel)\naddlib $(liblz4)\naddlib $(libz)\nsave\nend' | ar -M

main.o: $(main)
	cp $(main) $@
	chmod +w $@
	strip -N main -N _main $@

stubs.o: stubs.c
	$(CC) -c -o $@ $<

%.o: %.c
	$(CC) -c -o $@ $< -I$(incdir) -Wall -Wextra -pedantic $(CFLAGS)

%_boot.o: %_boot.c
	$(CC) -o $@ -c $(CFLAGS) $<

%_boot.c: %.boot
	$(runscheme) --script build-included-binary-file.ss "$@" chezschemebootfile $^

$(fcs): $(psboot) $(csboot) $(custom_boot)
	$(runscheme) --script make-boot-file.ss $@ $^

$(pcs): $(psboot) $(custom_boot)
	$(runscheme) --script make-boot-file.ss $@ $^

$(psboot) $(csboot) $(kernel) $(liblz4) $(libz) $(main):
	@echo Unable to find "$@". Try running gen-config.ss to set dependency paths
	@false

install: compile-chez-program
	install -d $(DESTDIR)$(installbindir)/
	install -m 755 compile-chez-program $(DESTDIR)$(installbindir)/
	install -d $(DESTDIR)$(installlibdir)/
	install -m 644 full-chez.a petite-chez.a $(DESTDIR)$(installlibdir)/

clean:
	rm -f compile-chez-program *.a *.generated.* *.s *.o *.chez *.so *.wpo *.boot

cleanconfig:
	rm -f config.ss make.in

uninstall:
	rm $(DESTDIR)$(installbindir)/compile-chez-program
	rm $(DESTDIR)$(installlibdir)/full-chez.a
	rm $(DESTDIR)$(installlibdir)/petite-chez.a

