*Seabrg signal generator
.SUBCKT Seabrg_src OutP OutN GND_SRC 
VSRCP OutP GND_SRC PWL (
+ 0.000000e+000 0.009799
+ 5.002221e-012 0.010032
+ 1.000444e-011 0.010232
+ 1.500666e-011 0.010391
+ 2.000888e-011 0.010503
+ 2.501110e-011 0.010571
+ 3.001333e-011 0.010595
+ 3.501555e-011 0.010577
+ 4.001777e-011 0.010522
+ 4.501999e-011 0.010432
)

VSRCN OutN GND_SRC PWL (
+ 0.000000e+000 -0.006980
+ 5.002221e-012 -0.007192
+ 9.890755e-012 -0.007399
+ 1.489298e-011 -0.007592
+ 1.989520e-011 -0.007769
+ 2.489742e-011 -0.007917
+ 2.989964e-011 -0.008033
+ 3.490186e-011 -0.008114
+ 3.990408e-011 -0.008162
+ 4.490630e-011 -0.008176
)

.ENDS