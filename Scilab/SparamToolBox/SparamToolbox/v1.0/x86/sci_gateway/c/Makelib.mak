# ------------------------------------------------------
# generated by builder.sce : Please do not edit this file
# see TEMPLATE makefile for Visual Studio
# see SCI/modules/dynamic_link/src/scripts/TEMPLATE_MAKEFILE.VC
# ------------------------------------------------------
SCIDIR = E:/SCILAB~1.0
SCIDIR1 = E:\SCILAB~1.0
# ------------------------------------------------------
# name of the dll to be built
LIBRARY = sparlib_c
# ------------------------------------------------------
# list of files
FILES_SRC = sptlbx_readtchstn.c sptlbx_writetchstn.c sparlib_c.c
# ------------------------------------------------------
# list of objects file
OBJS = sptlbx_readtchstn.obj sptlbx_writetchstn.obj sparlib_c.obj
OBJS_WITH_PATH = Release/sptlbx_readtchstn.obj Release/sptlbx_writetchstn.obj Release/sparlib_c.obj
# ------------------------------------------------------
# added libraries
FORTRAN_RUNTIME_LIBRARIES = 
OTHERLIBS = ../../src/c/liberr_codes.lib ../../src/c/libread_tchstn.lib ../../src/c/libwrite_tchstn.lib
# ------------------------------------------------------
!include $(SCIDIR1)\modules\dynamic_link\src\scripts\Makefile.incl.mak
# ------------------------------------------------------
#CC = 
# ------------------------------------------------------
CFLAGS = $(CC_OPTIONS) -DFORDLL -I"E:\scilab-5.2.0\contrib\SparamToolbox\sci_gateway\c\../../src/c" 
# ------------------------------------------------------
FFLAGS = $(FC_OPTIONS) -DFORDLL  
# ------------------------------------------------------
EXTRA_LDFLAGS = 
# ------------------------------------------------------
!include $(SCIDIR1)\modules\dynamic_link\src\scripts\Makedll.incl
# ------------------------------------------------------