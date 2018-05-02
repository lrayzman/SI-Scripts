// This file is released under the 3-clause BSD license. See COPYING-BSD.
// Generated by builder.sce : Please, do not edit this file
// ----------------------------------------------------------------------------
//
if ~win64() then
  warning(_("This module requires a Windows x64 platform."));
  return
end
//
sparlib_c_path = get_absolute_file_path('loader.sce');
//
// ulink previous function with same name
[bOK, ilib] = c_link('sparlib_c');
if bOK then
  ulink(ilib);
end
//
link(sparlib_c_path + filesep() + '../../src/c/liberr_codes' + getdynlibext());
link(sparlib_c_path + filesep() + '../../src/c/libread_tchstn' + getdynlibext());
link(sparlib_c_path + filesep() + '../../src/c/libwrite_tchstn' + getdynlibext());
list_functions = [ 'sptlbx_readtchstn';
                   'sptlbx_writetchstn';
];
addinter(sparlib_c_path + filesep() + 'sparlib_c' + getdynlibext(), 'sparlib_c', list_functions);
// remove temp. variables on stack
clear sparlib_c_path;
clear bOK;
clear ilib;
clear list_functions;
// ----------------------------------------------------------------------------
