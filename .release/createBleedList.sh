#!/bin/sh

echo "Fetching bleed list..."

DATE=$(date -d "today" +"%Y%m%d%H%M")

curl https://wago.tools/db2/SpellEffect/csv -o wow_db2_spelleffect_$DATE.csv

cat wow_db2_spelleffect_$DATE.csv | cut -d, -f13,36 | grep "^15,.*" | cut -d, -f2 > wow_bleed_list_$DATE.txt

curl https://wago.tools/db2/SpellCategories/csv -o wow_db2_spellcategories_$DATE.csv

cat wow_db2_spellcategories_$DATE.csv | cut -d, -f6,10 | grep "^15,.*" | cut -d, -f2 | sort | uniq > wow_spellcategories_mechanic_15_$DATE.txt
cat wow_db2_spelleffect_$DATE.csv | cut -d, -f5,36 | grep "^6,.*" | cut -d, -f2 | sort | uniq > wow_spelleffect_effectaura_6_$DATE.txt

join wow_spellcategories_mechanic_15_$DATE.txt wow_spelleffect_effectaura_6_$DATE.txt | sort -n | uniq >> wow_bleed_list_$DATE.txt

cat wow_bleed_list_$DATE.txt | sort -n | uniq > wow_bleed_list_sorted_$DATE.txt

cat << EOF > VuhDoDebuffConstBleed.lua.$DATE
-- VuhDoDebuffConstBleed.lua.$DATE
VUHDO_DEBUFF_BLEED_SPELLS = {
EOF

IFS="
"

for SPELL_ID in `cat wow_bleed_list_sorted_$DATE.txt`; do
	echo "\t[$SPELL_ID] = true," >> VuhDoDebuffConstBleed.lua.$DATE
done
	
echo "};" >> VuhDoDebuffConstBleed.lua.$DATE

rm -f wow_db2_spelleffect_$DATE.csv
rm -f wow_db2_spellcategories_$DATE.csv
rm -f wow_spellcategories_mechanic_15_$DATE.txt
rm -f wow_spelleffect_effectaura_6_$DATE.txt
rm -f wow_bleed_list_$DATE.txt
rm -f wow_bleed_list_sorted_$DATE.txt

echo "Complete."

exit 0
