.PHONY: all run clean

SUBDIRECTORIES := $(shell ls -d */)

all:
	mkdir -p scratch_output
	for DIR in $(SUBDIRECTORIES) ; do $(MAKE) -C $$DIR all ; done

run:
	@for DIR in $(SUBDIRECTORIES) ; do $(MAKE) -C $$DIR run ; done

clean:
	for DIR in $(SUBDIRECTORIES) ; do $(MAKE) -C $$DIR clean ; done
	rm -rf scratch_output
