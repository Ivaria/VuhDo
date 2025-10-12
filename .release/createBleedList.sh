#!/bin/sh

usage() {

	cat <<-'EOF'
	Usage: createBleedList.sh [OPTIONS] [VERSION|BRANCH]

	Generate a Lua table of bleed spell IDs from Wago Tools DB2 data.

	OPTIONS:
	  -h, --help     Show this help message

	ARGUMENTS:
	  VERSION        Specific version to fetch (e.g., 11, 11.0.7, 12.0.0)
	                 Searches across all branches for matching version

	  BRANCH         Branch/flavor name to fetch latest from:
	                 Friendly names:
	                   retail, mainline       - Latest retail (wow)
	                   beta                   - Latest retail beta (wow_beta)
	                   ptr, retail-ptr        - Retail PTR (wowxptr)
	                   classic                - Latest classic progression (wow_classic)
	                   classic-beta           - Beta for classic progression (wow_classic_beta)
	                   classic-ptr            - Classic progression PTR (wow_classic_ptr)
	                   vanilla, classic-era   - Classic Era, vanilla (wow_classic_era)
	                   vanilla-ptr, era-ptr   - Classic Era PTR (wow_classic_era_ptr)
	                   bcc, tbc               - Alias for classic progression
	                   wrath, wotlkc          - Alias for classic progression
	                   cata, catac            - Alias for classic progression
	                   mists, mopc            - Alias for classic progression

	                 Direct branch names:
	                   wow, wow_beta, wow_classic, wow_classic_beta,
	                   wow_classic_era, wow_classic_era_ptr, wow_classic_ptr,
	                   wowxptr

	  (no argument)  Defaults to latest retail build

	EXAMPLES:
	  createBleedList.sh              # No args: defaults to latest retail
	  createBleedList.sh retail       # Using an alias (retail → wow)
	  createBleedList.sh wow_beta     # Using direct branch name
	  createBleedList.sh 11           # Version search: latest 11.x from any branch
	  createBleedList.sh 11.0.7       # Version search: specific 11.0.7.x
	EOF
}

resolve_branch_alias() {

	local input=$(echo "$1" | tr '[:upper:]' '[:lower:]')

	case $input in
		retail|mainline)
			echo "wow"
			;;
		beta)
			echo "wow_beta"
			;;
		ptr|retail-ptr)
			echo "wowxptr"
			;;
		classic|bcc|tbc|wrath|wotlkc|cata|catac|mists|mopc)
			echo "wow_classic"
			;;
		classic-beta)
			echo "wow_classic_beta"
			;;
		classic-ptr)
			echo "wow_classic_ptr"
			;;
		vanilla|classic-era)
			echo "wow_classic_era"
			;;
		vanilla-ptr|era-ptr)
			echo "wow_classic_era_ptr"
			;;
		*)
			echo "$1"
			;;
	esac

}

while getopts ":h-:" opt; do
	case $opt in
		h) usage; exit 0 ;;
		-)
			case $OPTARG in
				help) usage; exit 0 ;;
				*)
					echo "Unknown option --$OPTARG" >&2
					usage
					exit 1
					;;
			esac
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			usage
			exit 1
			;;
	esac
done

shift $((OPTIND - 1))

BUILD_INPUT=$1

if ! command -v jq > /dev/null 2>&1; then
	echo "Error: jq is required but not installed. Please install jq."

	exit 1
fi

if [ -z "$BUILD_INPUT" ]; then
	echo "No parameter specified, using latest retail build..."

	BUILD_BRANCH="wow"
	IS_BRANCH=1
elif echo "$BUILD_INPUT" | grep -q '^[0-9]'; then
	echo "Fetching build information for version $BUILD_INPUT across all branches..."

	IS_BRANCH=0
else
	BUILD_BRANCH=$(resolve_branch_alias "$BUILD_INPUT")

	if [ "$BUILD_BRANCH" != "$BUILD_INPUT" ]; then
		echo "Fetching latest build from $BUILD_INPUT (${BUILD_BRANCH})..."
	else
		echo "Fetching latest build from branch $BUILD_INPUT..."
	fi

	IS_BRANCH=1
fi

BUILDS_JSON=$(curl -s https://wago.tools/api/builds)

if [ -z "$BUILDS_JSON" ]; then
	echo "Error: Could not fetch builds from wago.tools"

	exit 1
fi

if [ "$IS_BRANCH" = "1" ]; then
	BUILD_PARAM=$(echo "$BUILDS_JSON" | jq -r --arg branch "$BUILD_BRANCH" '.[$branch][0].version // empty')

	if [ -z "$BUILD_PARAM" ]; then
		echo "Error: Could not find builds for branch '$BUILD_BRANCH'"
		echo "Available branches: $(echo "$BUILDS_JSON" | jq -r 'keys[]' | tr '\n' ' ')"

		exit 1
	fi

	echo "Using latest from $BUILD_BRANCH: $BUILD_PARAM"
else
	BUILD_PARAM=$(echo "$BUILDS_JSON" | jq -r --arg version "$BUILD_INPUT" '.[] | .[] | select(.version | startswith($version)) | .version' | head -n 1)

	if [ -z "$BUILD_PARAM" ]; then
		echo "Error: Could not find build matching '$BUILD_INPUT' in any branch"

		exit 1
	fi

	echo "Resolved to build: $BUILD_PARAM"
fi

MAJOR_VERSION=$(echo "$BUILD_PARAM" | cut -d. -f1)

if [ "$MAJOR_VERSION" -ge 12 ]; then
	SPELL_EFFECT_SPELLID_COL=37
else
	SPELL_EFFECT_SPELLID_COL=36
fi

SPELL_EFFECT_EFFECTMECHANIC_COL=13
SPELL_EFFECT_EFFECT_COL=5
SPELL_CATEGORIES_MECHANIC_COL=6
SPELL_CATEGORIES_SPELLID_COL=10

BUILD_QUERY="?build=$BUILD_PARAM"

echo "Fetching bleed list..."

DATE=$(date -d "today" +"%Y%m%d%H%M")

curl "https://wago.tools/db2/SpellEffect/csv$BUILD_QUERY" -o wow_db2_spelleffect_$DATE.csv

cat wow_db2_spelleffect_$DATE.csv | cut -d, -f$SPELL_EFFECT_EFFECTMECHANIC_COL,$SPELL_EFFECT_SPELLID_COL | grep "^15,.*" | cut -d, -f2 > wow_bleed_list_$DATE.txt

curl "https://wago.tools/db2/SpellCategories/csv$BUILD_QUERY" -o wow_db2_spellcategories_$DATE.csv

cat wow_db2_spellcategories_$DATE.csv | cut -d, -f$SPELL_CATEGORIES_MECHANIC_COL,$SPELL_CATEGORIES_SPELLID_COL | grep "^15,.*" | cut -d, -f2 | sort | uniq > wow_spellcategories_mechanic_15_$DATE.txt
cat wow_db2_spelleffect_$DATE.csv | cut -d, -f$SPELL_EFFECT_EFFECT_COL,$SPELL_EFFECT_SPELLID_COL | grep "^6,.*" | cut -d, -f2 | sort | uniq > wow_spelleffect_effectaura_6_$DATE.txt

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