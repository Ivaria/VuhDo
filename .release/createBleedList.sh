#!/bin/sh

echo "Fetching bleed list..."

DATE=$(date -d "today" +"%Y%m%d%H%M")

curl https://wago.tools/db2/SpellEffect/csv -o wow_db2_spelleffect_$DATE.csv

cat wow_db2_spelleffect_$DATE.csv | cut -d, -f13,36 | grep "15,.*" | cut -d, -f2 | sort -n | uniq > wow_bleed_list_$DATE.txt

cat << EOF > VuhDoDebuffConstBleed.lua.$DATE
-- VuhDoDebuffConstBleed.lua.$DATE
VUHDO_DEBUFF_BLEED_SPELLS = {
EOF

IFS="
"

for SPELL_ID in `cat wow_bleed_list_$DATE.txt`; do
	echo "\t[$SPELL_ID] = true," >> VuhDoDebuffConstBleed.lua.$DATE
done
	
echo "};" >> VuhDoDebuffConstBleed.lua.$DATE

rm -f wow_db2_spelleffect_$DATE.csv
rm -f wow_bleed_list_$DATE.txt

echo "Complete."

exit 0
