:

init()
{
echo "Initialization"
		if test -d taf_nat
		then
		echo "Cleaning of the directory."
		rm -r taf_nat
		mkdir taf_nat
		else echo "Creation of the directory."
		mkdir taf_nat
		echo "Directory created."
		fi
}

download()
{
	country=$1
	if [ "$1" = "de" ] || [ "$1" = "fr" ] || [ "$1" = "it" ] || [ "$1" = "bl" ] || [ "$1" = "po" ] || [ "$1" = "es" ] || [ "$1" = "as" ] || [ "$1" = "ch" ]
	then
	if test -d "taf_nat"
	then
		cd taf_nat
		if [ ! -s "taf_txt_$country" ] || [ ! -s "taf_html_$country" ]
		then
		echo "Downloading"
		curl --get http://wx.rrwx.com/taf-$country-txt.htm > taf_txt_$country
		curl --get http://wx.rrwx.com/taf-$country.htm > taf_html_$country
		else echo "File taf_$country has been already downloaded."
		fi
		cd ..

	else echo "Error, you must initiate the script first."
	fi
	else echo "The country,you want is not in the list."
	fi
}

extract()
{
	country="$1"
	airport="$2"
	if [ "$1" = "de" ] || [ "$1" = "fr" ] || [ "$1" = "it" ] || [ "$1" = "bl" ] || [ "$1" = "po" ] || [ "$1" = "es" ] || [ "$1" = "as" ] || [ "$1" = "ch" ]
		then		
		cd taf_nat
		sed -n '/'"$airport"'/p' taf_html_"$country" > taf_temp_"$country"_"$airport" # M'extrait la ligne voule
		code=$(sed -n 's:.*<td valign="top"><b>\([A-Z][A-Z][A-Z][A-Z]\)</b>.*:\1:p' taf_temp_"$country"_"$airport") # M'extrait le code entouré de son code html
		echo "$code" > taf_temp_code
		echo "$airport" >  taf_temp_airport
		sed -n '/'"$code"'/p' taf_txt_"$country" > taf_to_extract
		tr " " "\n" < taf_to_extract > taf_extract_1
		cd ..
		else echo "Country not in the list."
	fi
}

analyze()
{
		cd taf_nat
		
		#month=$(date +%b)
		if test $(date +%b) = "févr."
		then month="Fev."
		fi

		if test $(date +%b) = "déce."
		then month="Dec."
		fi

		#if [ "$mois" = "fév." ]
		#then month="Fév"
		#fi		
		
		echo '<html>' > taf.html
		echo '<head><title>"TAF"</TITLE></HEAD>' >> taf.html
		echo '<body>' >> taf.html
		echo '<h2> TAF </h2>' >> taf.html
		echo '<ul>' >> taf.html
		while read line_temp
		do
		set -- $line_temp
		code="$1"
		done < taf_temp_code
		
		while read line_t
		do
		set -- $line_t
		airport="$1 $2"
		done < taf_temp_airport

		while read line
		do
		set -- $line
		#heure=$(sed -n ':.*[0-9][0-9]\([0-9][0-9])[0-9][0-9]Z :\1:p' taf_to_extract)
		#echo $line

		if [ "$line" = "$code" ]
		then echo "<li> Airport : $code </li>" >> taf.html
		fi
 
		
		if [ "${line:6:1}" = "Z" ]
		then echo "<br/><li>Emitted : ${line:0:2} $month @ ${line:2:2}H${line:4:2}</li>" >> taf.html
		#Février, Aout, Décembre
		fi
		
		if [ "${line:4:1}" = "/" ]
		then echo "<br/><li>Periode : ${line:0:2} $month @ ${line:2:2}H00M .. ${line:5:2} $month @ ${line:7:2}H00M</li>" >> taf.html
		fi

		if [ "${line:5:1}" = "G" ]
		then echo "<br/><li>Wind : ${line:0:3} @ ${line:3:2} KT with Gust @ ${line:6:2} KT</li>" >> taf.html
		fi
		
		if [ "${line:5:2}" = "KT" ]
		then echo "<br/><li>Winds : ${line:0:3} @ ${line:3:2} KT</li>" >> taf.html
		fi

		if [ "${line:0:3}" = "FEW" ]
		then echo "<br/><li>Clouds : few @ `expr ${line:3:3} \* 1`00 ft</li>" >> taf.html
		fi

		if [ "${line:0:3}" = "SCT" ]
		then echo "<br/><li>Clouds : scattered @ `expr ${line:3:3} \* 1`00 ft</li>" >> taf.html
		fi
		
		if [ "${line:0:3}" = "BKN" ]
		then echo "<br/><li>Clouds : broken @ `expr ${line:3:3} \* 1`00 ft</li>" >> taf.html
		fi

		if [ "${line:0:2}" = "RA" ]
		then echo "<br/><li> Précipitations : Pluie</li>" >> taf.html
		fi

		if [ "${line:0:3}" = "OVC" ]
		then echo "<br/><li>Clouds : overcast @ `expr ${line:3:3} \* 1`00 ft</li>" >> taf.html
		fi

		if echo ${line}| egrep -q '^[0-9]+$';
		then 
		echo "<br/><li>Visibility : $line meters</li>">> taf.html
		fi

		if [ "$line" = "CAVOK" ]
		then echo "<br/><li>Clouds : OK</li>" >> taf.html
		fi

		if [ "$line" == "BECMG" ]
		then echo "</ul><br/><h2>Becoming</h2><ul>" >> taf.html
		fi

		if [ "$line" == "TEMPO" ]
		then echo "</ul><br/><h2>Temporary</h2><ul>" >> taf.html
		fi

		if [ "$line" == "PROB30" ]
		then echo "</ul><h2>Probability of 30%</h2><ul>">> taf.html
		fi

		if [ "$line" == "PROB40" ]
		then echo "</ul><h2>Probability of 40%</h2><ul>" >> taf.html
		fi
		
		done < taf_extract_1
		
		#Création de la page html


		echo '</ul>' >> taf.html
		echo '</body>' >> taf.html
		echo '</html>' >> taf.html
		cd ..
}

combo()
{
download "$1"
extract "$1" "$2"
analyze
}

plan()
{
download "$1"
extract "$1" "$2"
analyze
cd taf_nat
cat taf.html > taf_trajet.html
cd ..
download "$3"
extract "$3" "$4"
analyze
cd taf_nat
cat taf.html >> taf_trajet.html
cd ..
}

main()
{
	case $1 in
	*i) init ;;
	*d) download "$2";;
	*e) extract "$2" "$3";;
	*a) analyze;;
	*p) combo "$2" "$3";;
	*t) plan "$2" "$3" "$4" "$5";;
	esac
}

while test $# -ne 0
do
main "$@"
shift
done
