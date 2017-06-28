function report_start () {
	printf "%-10s .......... " $1
}

function report_filename() {
	echo "$1_tmp.txt"
}

function report_result() {
	#
	#	Convert any dates in shmig output to the string "*now*"
	#	so expected matches actual output.
	#
	
	sed 's/20..-[012].-[0123]. ..:..:..\(\.[0-9]*\)*/*now*/' $1_tmp.txt > $1_actual.txt
	if diff -uw $1_expected.txt $1_actual.txt >/dev/null
	then
		printf "PASS\n" $1
	else
		printf "FAIL (diff below)\n" $1
		diff -uw $1_expected.txt $1_actual.txt
	fi
}
