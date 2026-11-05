# batch_bss.csh - script to try Blue Straggler experiment
# TvH: Nov 2-3, 2024

# in dr. vonHippel's example/code, there is one star. for multiple stars, each would have their own phot file.
set photfiles = (2893942062036323200.phot)

# this file contains the results of the cluster run, with burnin removed.
set resfile   = NGC_2243_trim.res

# the above res file looks like this:
#  logAge         FeH     modulus  absorption      logPost     stage
#  9.386280   -0.028635   12.469337    0.551811 -3724.339345          3
#  9.385701   -0.031793   12.470974    0.553240 -3724.123760          3
#   .           .           .           .            .                .

#will use the logAge, FeH, modulus, and absorption values with sigma=0 at each iteration
#running singlePopMcmc and sampleMass while setting a pretty broad flat prior on logAge

set modelFile     = "PARSEC/PARSEC.model"
set age_info      = "--startingLogAge 9.5 --priorLogAge 9.5"	# .inf already in base9.yaml file
set options       = "--noBinaries"
    #we may or may not want this option
set options       = ($options --maxIter 2000)
set epsilon       = 0.0001
    #very small error for sampling in FeH, modulus, Av

set star_count    = 1
set clus_iter     = 1
set max_clus_iter = 500
set thinning      = 20
    #jump forward in the chain this many iterations

while ($star_count <= $#photfiles)
   set photfile = $photfiles[$star_count]
   set outfile  = $photfile:r.tmp

   while ($clus_iter <= $max_clus_iter)
      set this_locn = $clus_iter
        #indexing through the resfile
      @ this_locn *= $thinning
      @ this_locn++
        #accounting for the file header
      set this_line = `head -$this_locn $resfile | tail -1`
        #grab that line
      set FeH       = $this_line[2]
      set modulus   = $this_line[3]
      set Av        = $this_line[4]

      set params = "--msModelFile $modelFile $options $age_info"
      set params = "$params --startingFe_H $FeH --priorFe_H $FeH --sigmaFe_H $epsilon"
      set params = "$params --startingDistMod $modulus --priorDistMod $modulus --sigmaDistMod $epsilon"
      set params = "$params --startingAv $Av --priorAv $Av --sigmaAv $epsilon"

      echo ""
      if($clus_iter == 1) then
         echo "singlePopMcmc --photFile $photfile --outputFileBase $outfile $params"
      else
         echo "params: [Fe/H] = $FeH m-M = $modulus Av = $Av epsilon = $epsilon"
      else
      endif
      singlePopMcmc --photFile $photfile --outputFileBase $outfile $params

      if($clus_iter == 1) then
         head -1 $outfile.res > $outfile:r.res
      endif
      tail -1 $outfile.res >> $outfile:r.res
        #only keeping the last iteration

      @ clus_iter++
   end

   rm $outfile.res						# the file with the .tmp in its name

   # now running sampleMass, which doesn't modify cluster params,  on the accumulated .res file

   echo "sampleMass --photFile $photfile --outputFileBase $outfile:r $params"
   sampleMass --photFile $photfile --outputFileBase $outfile:r $params

   #cut -c1-12,34-44 $photfile.sampleMass.out > $photfile.mass.clean
   #paste -d" " $photfile.res $photfile.mass.clean > $photfile.comb
   
   cut -c1-12,34-44 $photfile:r.sampleMass.out > $photfile.mass.clean
   paste -d" " $photfile:r.res $photfile.mass.clean > $photfile.comb

   @ star_count++
end

#messgae produced once code has finished running
echo ""
echo " Done running singlePopMcmc and sampleMass for $#photfiles stars and $max_clus_iter iterations."
