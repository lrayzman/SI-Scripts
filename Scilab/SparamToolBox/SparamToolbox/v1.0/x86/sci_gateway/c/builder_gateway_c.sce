// ====================================================================
// Allan CORNET
// Simon LIPP
// INRIA 2008
// This file is released into the public domain
// ====================================================================

if MSDOS then
  // to manage long pathname
  includes_src_c = '-I""' + get_absolute_file_path('builder_gateway_c.sce') + '../../src/c""';
else
  includes_src_c = '-I' + get_absolute_file_path('builder_gateway_c.sce') + '../../src/c';
end

// PutLhsVar managed by user in sci_sum and in sci_sub
// if you do not this variable, PutLhsVar is added
// in gateway generated (default mode in scilab 4.x and 5.x)
WITHOUT_AUTO_PUTLHSVAR = %t;

tbx_build_gateway('sparlib_c', ['sptlbx_readtchstn','sptlbx_readtchstn';'sptlbx_writetchstn','sptlbx_writetchstn' ],..
                  ['sptlbx_readtchstn.c', 'sptlbx_writetchstn.c'], ..
                  get_absolute_file_path('builder_gateway_c.sce'), ..
                  ['../../src/c/liberr_codes', '../../src/c/libread_tchstn', '../../src/c/libwrite_tchstn'],'',includes_src_c);

clear WITHOUT_AUTO_PUTLHSVAR;

clear tbx_build_gateway;
