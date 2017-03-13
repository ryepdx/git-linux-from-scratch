ifndef LFS
	LFS=/
endif
ifndef LFS_TGT
	LFS_TGT=$(LFS)
endif
ifndef LFS_SRC
	LFS_SRC=$(LFS)/src
endif
ifndef BEEP
	BEEP=echo "DONE."
endif


###
# top-level jobs
###

cross-compile: binutils gcc-pass1

native-compile: binutils

cross-install: binutils-install gcc-pass1-install

toolchain-pre: /tools/lib64

clean: binutils-clean


###
# binutils
###

ifndef BINUTILS_SRC
	BINUTILS_SRC=$(LFS_SRC)/binutils-gdb
endif

binutils: $(BINUTILS_SRC)/build

/tools/lib64:
	case $$(uname -m) in \
	    x86_64) mkdir -v /tools/lib || ln -sv lib /tools/lib64 ;; \
	esac

$(BINUTILS_SRC)/build: $(BINUTILS_SRC)/build/.dirstamp
	cd $@ && \
	$(BINUTILS_SRC)/configure           \
	         --prefix=/tools            \
	         --with-sysroot=$(LFS)       \
	         --with-lib-path=/tools/lib \
	         --target=$(LFS_TGT)        \
	         --disable-nls              \
	         --disable-werror &&        \
	make && $(BEEP)

$(BINUTILS_SRC)/build/.dirstamp:
	mkdir -v -p $(BINUTILS_SRC)/build && touch $@

binutils-install: $(BINUTILS_SRC)/build
	cd $(BINUTILS_SRC)/build && make install

binutils-clean:
	rm -fr $(BINUTILS_SRC)/build


###
# gmp
###

GMP_SRC=$(LFS_SRC)/gmp


###
# mpfr
###

MPFR_SRC=$(LFS_SRC)/mpfr


###
# mpc
###

MPC_SRC=$(LFS_SRC)/mpc


###
# gcc
###

GCC_SRC=$(LFS_SRC)/gcc

$(GCC_SRC)/gmp:
	ln -s $(GMP_SRC) $@

$(GCC_SRC)/mpfr:
	ln -s $(MPFR_SRC) $@

$(GCC_SRC)/mpc:
	ln -s $(MPC_SRC) $@

gcc-pass1-prep: $(GCC_SRC)/gmp $(GCC_SRC)/mpfr $(GCC_SRC)/mpc
	# Change the location of GCC's default dynamic linker to use the one
	# installed in /tools. Also remove /usr/include from GCC's include
	# search path.
	cd $(GCC_SRC) && \
	for file in gcc/config/{linux,i386/linux{,64}}.h; do \
		  cp -uv $$file{,.orig} && \
		  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
		      -e 's@/usr@/tools@g' $$file.orig > $$file && \
		  echo ' \
		#undef STANDARD_STARTFILE_PREFIX_1 \
		#undef STANDARD_STARTFILE_PREFIX_2 \
		#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/" \
		#define STANDARD_STARTFILE_PREFIX_2 ""' >> $$file && \
		touch $$file.orig; \
		done \
	&& \
	case $$(uname -m) in \
		x86_64) sed -e '/m64=/s/lib64/lib/' \
			-i.orig gcc/config/i386/t-linux64 \
 		;; \
	esac; \

$(GCC_SRC)/build: $(GCC_SRC)/build/.dirstamp
	cd $@ && \
	../configure                                       \
		--target=$(LFS_TGT)                            \
		--prefix=/tools                                \
		--with-glibc-version=2.11                      \
		--with-sysroot=$LFS                            \
		--with-newlib                                  \
		--without-headers                              \
		--with-local-prefix=/tools                     \
		--with-native-system-header-dir=/tools/include \
		--disable-nls                                  \
		--disable-shared                               \
		--disable-multilib                             \
		--disable-decimal-float                        \
		--disable-threads                              \
		--disable-libatomic                            \
		--disable-libgomp                              \
		--disable-libmpx                               \
		--disable-libquadmath                          \
		--disable-libssp                               \
		--disable-libvtv                               \
		--disable-libstdcxx                            \
		--enable-languages=c,c++ && \
	make

$(GCC_SRC)/build/.dirstamp:
	mkdir -v -p $(GCC_SRC)/build && touch $@

gcc-pass1: gcc-pass1-prep $(GCC_SRC)/build

gcc-pass1-install: $(GCC_SRC)/build
	cd $(GCC_SRC)/build && make install

gcc-pass1-clean:
	rm -fr $(GCC_SRC)/build


