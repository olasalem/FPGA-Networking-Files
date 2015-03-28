setMode -bscan
setCable -p auto
addDevice -p 1 -file "../syn/s3_digilent.bit"
addDevice -p 2 -sprom xcf02s -file "../syn/s3_digilent.mcs"

program -p 1 -e -loadfpga 
program -p 2 -e -prog -loadfpga

quit
