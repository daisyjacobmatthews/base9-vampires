### runs MakeCMD for all clusters in the cluster folder

foreach dir (clusters/*)
    if ( -d "$dir" ) then
        cd $dir
        if ( -e "base9.yaml" ) then
        	echo "Found base9.yaml for $dir"
        	makeCMD
			echo "makeCMD run for $dir"
        else
        	echo "Missing base9.yaml for $dir"
        endif
    	cd ../..
    endif
end