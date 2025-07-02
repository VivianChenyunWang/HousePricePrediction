/* 
* TODO: 1. Place the .txt data file and the dictionary file you downloaded in the work folder, or enter the full path to these files!
*       2. You may have to increase memory using the 'set mem' statement. It is commented out in the code bellow.
*
* If you have any questions or need assistance contact info@socialexplorer.com.
*/

///set mem 512m
clear all
set more off
infile using "C:\Users\Vivian Wang\Desktop\SOC2960 Spatial\FinalProject\ACS2022_5yr_R13779428.dct", using("C:\Users\Vivian Wang\Desktop\SOC2960 Spatial\FinalProject\ACS2022_5yr_R13779428_SL140.txt") clear

cd "C:\Users\Vivian Wang\Desktop\SOC2960 Spatial\FinalProject"
use ACS2022_5yr_R13779428,clear

clear all
ssc install spmap
ssc instal shp2dta
cd "C:\Users\Vivian Wang\Desktop\SOC2960 Spatial\FinalProject"
shp2dta using "philly.shp", database(phillydb) coordinates(phillycoord) genid(id)
use phillydb, clear
rename GEOID10 FIPS
merge m:1 FIPS using ACS2022_5yr_R13779428
drop if _merge==1 & _merge==2
drop if ALAND10==.

rename B01003001 totpop
rename B11001002 famhousehold
rename B25010001 avghhsize
rename B19013001 hhincome
rename B19301001 perincome
rename B25002003 vacantnum
rename B25003003 rentnum
rename B25064001 medrent
rename B25071001 percrent
rename B25096001 mortgage
rename B25035001 medbuilt
rename B08006002 car
rename B08006008 transp
gen workhome=B08006014+B08006015+B08006017
rename B08013001 mintransp
rename B03002012 hispop
rename B03002003 nonhiswhite
rename B03002004 nonhisblack
rename B03002006 nonhisasian
gen nonhisother= B03002005+B03002007+B03002008+B03002009
rename B15003022 bachelor
rename B15003024 master
rename B15003025 phd
gen higherdg= master+phd
rename B25077001 medhousevalue
save "C:\Users\Vivian Wang\Desktop\SOC2960 Spatial\FinalProject\ACS2022_5yr_R13779428.dta", replace


*****the maps****************************************
spmap medhousevalue using phillycoord,id(id) fcolor(Blues) clnumber(9) legend(position(5)) title("Median House Values in Philadelphia")
spmap perincome using phillycoord,id(id) fcolor(Greens) clnumber(9) legend(position(5)) title("Per Capita Income in Philadelphia")
spmap totpop using phillycoord,id(id) fcolor(Purples) clnumber(9) legend(position(5)) title("Total Population in Philadelphia")
spmap perhighdg using phillycoord,id(id) fcolor(Purples) clnumber(9) legend(position(5)) title("Percentage of Higher Degree in Philadelphia")
spmap perworkhome using phillycoord,id(id) fcolor(Oranges) clnumber(9) legend(position(5)) title("Percentage of People Work Near Home in Philadelphia")
spmap avgage using phillycoord,id(id) fcolor(Blues) clnumber(9) legend(position(5)) title("Average House Age in Philadelphia")
spmap perhis using phillycoord,id(id) fcolor(Greens) clnumber(9) legend(position(5)) title("Percentage of Hispanic Population in Philadelphia")
spmap perblack using phillycoord,id(id) fcolor(Reds) clnumber(9) legend(position(5)) title("Percentage of Black Population in Philadelphia")
spmap permort using phillycoord,id(id) fcolor(Oranges) clnumber(9) legend(position(5)) title("Percentage of People with Mortgage in Philadelphia")
spmap mintransp using phillycoord,id(id) fcolor(Greens) clnumber(9) legend(position(5)) title("Minute of Transportation to Work in Philadelphia")
spmap pervacant using phillycoord,id(id) fcolor(Blues) clnumber(9) legend(position(5)) title("Percentage of Vacant House in Philadelphia")

gen lat = real(INTPTLAT10)
gen lon = real(INTPTLON10)
spset id, coord(lon lat)
spset, modify coordsys(planar)
spset, modify shpfile(phillycoord)

*****the queen and distance matrix is here*******
spmatrix create contiguity W_queen, first normalize(row) replace
spmatrix create idistance W_dist, vtruncate(3) normalize(row) replace
spmatrix export W_dist using W_dist.txt, replace
spmatrix export W_dist using W_dist.dta, replace


drop if medhousevalue==.
save "C:\Users\Vivian Wang\Desktop\SOC2960 Spatial\FinalProject\ACS2022_5yr_R13779428.dta", replace

*****segregation****************************************
drop d_bw
seg nonhiswhite nonhisblack, gen(d d_bw) d
seg nonhiswhite nonhisasian, gen(d d_aw) d
seg nonhisblack nonhisasian, gen(d d_ab) d
seg nonhisblack nonhisother, gen(d d_bo) d
seg hispop nonhisblack, gen(d d_bh) d
seg hispop nonhiswhite, gen(d d_wh) d
seg hispop nonhisasian, gen(d d_ah) d
set linesize 255
sum d_bw d_ab d_bh d_aw d_ah

****variable engineering***********************************
regress medhousevalue
estat moran, errorlag(W_queen)

sum medhousevalue
histogram medhousevalue, bin(35) frequency
gen lmedhousevalue=ln(medhousevalue)
sum lmedhousevalue
histogram lmedhousevalue, bin(35) frequency
histogram totpop, bin(35) frequency
ladder totpop
gen sqtotpop=sqrt(totpop)
histogram sqtotpop, bin(35) frequency
scatter lmedhousevalue totpop

ladder hispop1
gen sqhispop=sqrt(hispop)
gen phispop=hispop/totpop
histogram phispop, bin(35) frequency
histogram sqhispop, bin(35) frequency
ladder sqhispop
histogram hispop, bin(35) frequency
drop lhispop
gen hispop1=hispop+1
gen lhispop=ln(hispop+1)
histogram lhispop
gen qrhispop=sqrt(sqhispop)
histogram qrhispop, bin(35) frequency
ladder qrhispop
scatter lmedhousevalue qrhispop

scatter lmedhousevalue nonhiswhite
scatter lmedhousevalue nonhisblack
ladder nonhisblack
gen nhblack1=nonhisblack+1
ladder nhblack1
ladder nonhiswhite
gen nhwhite1=nonhiswhite+1
ladder nhwhite1

gen sqhighdg=sqrt(higherdg)
gen qrhighdg=sqrt(sqhighdg)
ladder qrhighdg
ladder higherdg
gen higherdg1=higherdg+1
ladder higherdg1
drop lhigherdg
gen lhigherdg=ln(higherdg1)
histogram higherdg, bin(35) frequency
histogram lhigherdg, bin(35) frequency
scatter lmedhousevalue qrhighdg

ladder perincome
histogram perincome, bin(35) frequency
histogram lperincome, bin(35) frequency
gen lperincome=ln(perincome)
gen isqperincome=1/sqrt(perincome)
scatter isqperincome lmedhousevalue
scatter lmedhousevalue lperincome

ladder mortgage
histogram mortgage, bin(35) frequency
gen sqmortgage=sqrt(mortgage)
histogram sqmortgage, bin(35) frequency
scatter lmedhousevalue sqmortgage

ladder vacantnum
gen vacantnum1=vacantnum+1
ladder vacantnum1
gen sqvacantnum=sqrt(vacantnum)
histogram sqvacantnum, bin(35) frequency
scatter lmedhousevalue sqvacantnum

ladder medbuilt
gen avgage=2024-medbuilt
gen avgage2=avgage^2
gen lavgage=ln(avgage)
histogram lavgage, bin(35) frequency
histogram avgage2, bin(35) frequency
drop if avgage>2000
ladder avgage
scatter lmedhousevalue avgage2

histogram workhome, bin(35) frequency
gen workhome1=workhome+1
ladder workhome1
gen lworkhome=ln(workhome1)
ladder workhome
gen sqworkhome=sqrt(workhome)
histogram sqworkhome, bin(35) frequency
ladder sqworkhome
gen qrworkhome=sqrt(sqworkhome)
scatter lmedhousevalue qrworkhome

ladder mintransp
gen mintransp1=mintransp+1
ladder mintransp1
histogram mintransp, bin(35) frequency
gen sqmintransp=sqrt(mintransp)
scatter lmedhousevalue sqmintransp

gen perhis=hispop/totpop
histogram perhis, bin(35) frequency

gen perwhite=nonhiswhite/totpop
histogram perwhite, bin(35) frequency

gen perblack=nonhisblack/totpop
histogram perblack, bin(35) frequency

gen perhighdg=higherdg/totpop
histogram perhighdg, bin(35) frequency

gen permort=mortgage/totpop
histogram permort, bin(35) frequency

rename B25002001 tothouse
gen pervacant=vacant/tothouse
histogram pervacant, bin(35) frequency

gen perworkhome=workhome/totpop
histogram perworkhome, bin(35) frequency


******this is the matrix for moran's I*********
import delimited W_dist.txt, clear
spatwmat, name(dist) xcoord(lon) ycoord(lat) band(0 0.1) standardize
spatwmat using "W_dist.txt", name(W_dist)
display dist
**********************************************
******EDA and Moran's I************************
regress perhis
estat moran, errorlag(W_queen)
spatgsa medhousevalue, weights(dist) m
spatgsa totpop, weights(dist) m
spatgsa perhis, weights(dist) m
spatgsa perblack, weights(dist) m
spatgsa perhighdg, weights(dist) m
spatgsa perincome, weights(dist) m
spatgsa permort, weights(dist) m
spatgsa pervacant, weights(dist) m
spatgsa avgage, weights(dist) m
spatgsa perworkhome, weights(dist) m
spatgsa mintransp, weights(dist) m

***this is the OLS final model*******
regress lmedhousevalue totpop perhis perblack perhighdg lperincome permort pervacant avgage perworkhome mintransp
estimates store OLS
drop resOLS
predict resOLS, residuals
spatgsa resOLS, weights(dist) m
estat moran, errorlag(W_queen)
estat ic
histogram resOLS, bin(35) frequency
predict student, rstudent
graph twoway scatter student medhousevalue || lfit student medhousevalue 
***********************************************
********these are the previous versions***************
regress medhousevalue totpop hispop nonhiswhite nonhisblack higherdg perincome mortgage vacantnum medbuilt workhome mintransp

regress lmedhousevalue totpop lhispop nonhiswhite nonhisblack qrhighdg isqperincome sqmortgage sqvacantnum avgage2 qrworkhome sqmintransp
regress lmedhousevalue totpop lhispop nonhiswhite nonhisblack lhigherdg lperincome mortgage vacantnum lavgage lworkhome mintransp
estimates store OLS
foreach var of varlist medhousevalue totpop avghhsize perincome vacantnum percrent mortgage medbuilt car transp workhome mintransp hispop nonhiswhite nonhisblack nonhisother bachelor master phd {
    replace `var' = 0 if missing(`var')
}
drop resOLS
predict resOLS, residuals
spatgsa resOLS, weights(dist) m
estat moran, errorlag(W_queen)
estat impact
estat ic


**************************************************
***********this is the SAR model*************
spregress lmedhousevalue totpop perhis perblack perhighdg lperincome permort pervacant avgage perworkhome mintransp, ml dvarlag(W_queen)
estimates store SAR
drop resSAR
predict resSAR, residuals
spatgsa resSAR, weights(dist) m
estat ic
estat impact
***********************************************
********these are the previous versions***************
spregress lmedhousevalue sqtotpop qrhispop nonhiswhite nonhisblack qrhighdg isqperincome sqmortgage sqvacantnum avgage2 qrworkhome sqmintransp, ml dvarlag(W_dist)
spregress lmedhousevalue sqtotpop qrhispop nonhiswhite nonhisblack qrhighdg isqperincome sqmortgage sqvacantnum avgage2 qrworkhome sqmintransp, ml dvarlag(W_queen)
spregress lmedhousevalue totpop lhispop nonhiswhite nonhisblack lhigherdg lperincome mortgage vacantnum lavgage lworkhome mintransp, ml dvarlag(W_queen)
spregress medhousevalue totpop hispop nonhiswhite nonhisblack higherdg perincome mortgage vacantnum medbuilt workhome mintransp, ml dvarlag(dist)


**************************************************
***********this is the SEM model*************
spregress lmedhousevalue totpop perhis perblack perhighdg lperincome permort pervacant avgage perworkhome mintransp, ml errorlag(W_queen)
estimates store SAR
drop resSEM
predict resSEM, residuals
spatgsa resSEM, weights(dist) m
estat ic
***********************************************
********these are the previous versions***************
spregress medhousevalue totpop hispop nonhiswhite nonhisblack higherdg perincome mortgage vacantnum medbuilt workhome mintransp, ml errorlag(W_queen)
estimates store SEM
drop resSEM
predict resSEM, residuals
spatgsa resSEM, weights(dist) m
estat ic
spregress lmedhousevalue sqtotpop qrhispop nonhiswhite nonhisblack qrhighdg isqperincome sqmortgage sqvacantnum avgage2 qrworkhome sqmintransp, ml errorlag(W_queen)
spregress lmedhousevalue sqtotpop qrhispop nonhiswhite nonhisblack qrhighdg isqperincome sqmortgage sqvacantnum avgage2 qrworkhome sqmintransp, ml errorlag(W_dist)
spregress lmedhousevalue totpop lhispop nonhiswhite nonhisblack lhigherdg lperincome mortgage vacantnum lavgage lworkhome mintransp, ml errorlag(W_queen)


**************************************************
***********this is the SAC model*************
spregress lmedhousevalue totpop perhis perblack perhighdg lperincome permort pervacant avgage perworkhome mintransp, ml dvarlag(W_queen) errorlag(W_queen)
estimates store SAC
drop resSAC
predict resSAC, residuals
spatgsa resSAC, weights(dist) m
estat ic
estat impact
margins, at(perhis=0.8 perblack=0.14 perhighdg=0.3 permort=0.1 pervacant=0.05 perworkhome=0.4)
***********************************************
********these are the previous versions***************
spregress lmedhousevalue sqtotpop qrhispop nonhiswhite nonhisblack qrhighdg isqperincome sqmortgage sqvacantnum avgage2 qrworkhome sqmintransp, ml dvarlag(W_queen) errorlag(W_queen)
spregress lmedhousevalue sqtotpop qrhispop nonhiswhite nonhisblack qrhighdg isqperincome sqmortgage sqvacantnum avgage2 qrworkhome sqmintransp, ml dvarlag(W_dist) errorlag(W_dist)
spregress lmedhousevalue totpop lhispop nonhiswhite nonhisblack lhigherdg lperincome mortgage vacantnum lavgage lworkhome mintransp, ml dvarlag(W_queen) errorlag(W_queen)

estimates dir
lrtest SAR SAC
lrtest SEM SAC



