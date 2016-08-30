// ====================================================================
// Allan CORNET
// Simon LIPP
// INRIA 2008
// This file is released into the public domain
// ====================================================================

src_c_path = get_absolute_file_path('builder_c.sce');

CFLAGS = "-I" + src_c_path;

tbx_build_src(['err_codes'], ['err_codes.c'], 'c', ..
                src_c_path, '', '', CFLAGS);

tbx_build_src(['read_tchstn'], ['read_tchstn.c'], 'c', ..
              src_c_path, 'liberr_codes', '', CFLAGS);

tbx_build_src(['write_tchstn'], ['write_tchstn.c'], 'c', ..
              src_c_path, 'liberr_codes', '', CFLAGS);




clear tbx_build_src;
clear src_c_path;
clear CFLAGS;
