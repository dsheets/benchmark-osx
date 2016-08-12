.PHONY: all run clean

all:
	$(MAKE) -C Sys.readdir
	$(MAKE) -C Unix.readdir
	$(MAKE) -C Dirent_unix.readdir
	$(MAKE) -C Osx_attr.getbulk
	$(MAKE) -C Osx_attr.getlistbulk
	$(MAKE) -C Lwt_unix.readdir
	$(MAKE) -C Dirent_unix_lwt.readdir
	$(MAKE) -C Osx_attr_lwt.getbulk
	$(MAKE) -C Osx_attr_lwt.getlistbulk
	$(MAKE) -C Async_sys.readdir
	$(MAKE) -C Async_unix.readdir

run:
	$(MAKE) -C Sys.readdir run
	$(MAKE) -C Unix.readdir run
	$(MAKE) -C Dirent_unix.readdir run
	$(MAKE) -C Osx_attr.getbulk run
	$(MAKE) -C Osx_attr.getlistbulk run
	$(MAKE) -C Lwt_unix.readdir run
	$(MAKE) -C Dirent_unix_lwt.readdir run
	$(MAKE) -C Osx_attr_lwt.getbulk run
	$(MAKE) -C Osx_attr_lwt.getlistbulk run
	$(MAKE) -C Async_sys.readdir run
	$(MAKE) -C Async_unix.readdir run

clean:
	$(MAKE) -C Sys.readdir clean
	$(MAKE) -C Unix.readdir clean
	$(MAKE) -C Dirent_unix.readdir clean
	$(MAKE) -C Osx_attr.getbulk clean
	$(MAKE) -C Osx_attr.getlistbulk clean
	$(MAKE) -C Lwt_unix.readdir clean
	$(MAKE) -C Dirent_unix_lwt.readdir clean
	$(MAKE) -C Osx_attr_lwt.getbulk clean
	$(MAKE) -C Osx_attr_lwt.getlistbulk clean
	$(MAKE) -C Async_sys.readdir clean
	$(MAKE) -C Async_unix.readdir clean
