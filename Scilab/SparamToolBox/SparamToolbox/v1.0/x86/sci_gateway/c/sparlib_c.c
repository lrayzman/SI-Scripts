#include <mex.h> 
#include <sci_gateway.h>
#include <api_scilab.h>
static int direct_gateway(char *fname,void F(void)) { F();return 0;};
extern Gatefunc sptlbx_readtchstn;
extern Gatefunc sptlbx_writetchstn;
static GenericTable Tab[]={
  {(Myinterfun)sci_gateway_without_putlhsvar,sptlbx_readtchstn,"sptlbx_readtchstn"},
  {(Myinterfun)sci_gateway_without_putlhsvar,sptlbx_writetchstn,"sptlbx_writetchstn"},
};
 
int C2F(sparlib_c)()
{
  Rhs = Max(0, Rhs);
  if (*(Tab[Fin-1].f) != NULL) 
  {
     pvApiCtx->pstName = (char*)Tab[Fin-1].name;
    (*(Tab[Fin-1].f))(Tab[Fin-1].name,Tab[Fin-1].F);
  }
  return 0;
}
