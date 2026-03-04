#!/bin/sh

usage() {

	cat <<-'EOF'
	Usage: createSecretSpellLists.sh [OPTIONS] [VERSION|BRANCH]

	Generate Lua tables of spell IDs by SpellMisc Attributes_15 secret flags from Wago Tools DB2 data.

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
	                   classic-ptr           - Classic progression PTR (wow_classic_ptr)
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
	  createSecretSpellLists.sh              # No args: defaults to latest retail
	  createSecretSpellLists.sh retail       # Using an alias (retail → wow)
	  createSecretSpellLists.sh wow_beta     # Using direct branch name
	  createSecretSpellLists.sh 11           # Version search: latest 11.x from any branch
	  createSecretSpellLists.sh 11.0.7       # Version search: specific 11.0.7.x
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

	BUILD_BRANCH=$(echo "$BUILDS_JSON" | jq -r --arg version "$BUILD_PARAM" 'to_entries[] | select(.value[] | .version == $version) | .key' | head -n 1)

	echo "Resolved to build: $BUILD_PARAM (branch: $BUILD_BRANCH)"
fi

SPELLMISC_ATTR15_COL=17
SPELLMISC_SPELLID_COL=34

BUILD_QUERY="?build=$BUILD_PARAM"

echo "Fetching secret spell lists..."

DATE=$(date -d "today" +"%Y%m%d%H%M")

curl "https://wago.tools/db2/SpellMisc/csv$BUILD_QUERY" -o wow_db2_spellmisc_$DATE.csv

gawk -M -F, -v date="$DATE" '
NR > 1 {
	attrs = $17 + 0
	if (attrs < 0) attrs += 4294967296
	spellid = $34
	if (spellid == "") next
	if (and(attrs, 524288))    print spellid >> ("wow_secret_CAST_ALWAYS_SECRET_" date ".txt")
	if (and(attrs, 1048576))   print spellid >> ("wow_secret_CAST_NEVER_SECRET_" date ".txt")
	if (and(attrs, 33554432))  print spellid >> ("wow_secret_AURA_ALWAYS_SECRET_" date ".txt")
	if (and(attrs, 67108864))  print spellid >> ("wow_secret_AURA_NEVER_SECRET_" date ".txt")
	if (and(attrs, 1073741824)) print spellid >> ("wow_secret_COOLDOWN_ALWAYS_SECRET_" date ".txt")
	if (and(attrs, 2147483648)) print spellid >> ("wow_secret_COOLDOWN_NEVER_SECRET_" date ".txt")
}
' wow_db2_spellmisc_$DATE.csv

for key in CAST_ALWAYS_SECRET CAST_NEVER_SECRET AURA_ALWAYS_SECRET AURA_NEVER_SECRET COOLDOWN_ALWAYS_SECRET COOLDOWN_NEVER_SECRET; do
	if [ -f "wow_secret_${key}_$DATE.txt" ]; then
		sort -n "wow_secret_${key}_$DATE.txt" | uniq > "wow_secret_${key}_sorted_$DATE.txt"
	else
		: > "wow_secret_${key}_sorted_$DATE.txt"
	fi
done

OUTFILE="VuhDoSecretSpellLists.lua.$DATE"

{
	echo "-- $OUTFILE (Build: $BUILD_PARAM, Branch: $BUILD_BRANCH)"
	echo "VUHDO_SPELL_CAST_ALWAYS_SECRET = {"

	if [ -s "wow_secret_CAST_ALWAYS_SECRET_sorted_$DATE.txt" ]; then
		IFS="
"
		for SPELL_ID in $(cat "wow_secret_CAST_ALWAYS_SECRET_sorted_$DATE.txt"); do
			echo "\t[$SPELL_ID] = true,"
		done
	fi

	echo "};"
	echo ""
	echo "VUHDO_SPELL_CAST_NEVER_SECRET = {"

	if [ -s "wow_secret_CAST_NEVER_SECRET_sorted_$DATE.txt" ]; then
		for SPELL_ID in $(cat "wow_secret_CAST_NEVER_SECRET_sorted_$DATE.txt"); do
			echo "\t[$SPELL_ID] = true,"
		done
	fi

	echo "};"
	echo ""
	echo "VUHDO_SPELL_AURA_ALWAYS_SECRET = {"

	if [ -s "wow_secret_AURA_ALWAYS_SECRET_sorted_$DATE.txt" ]; then
		for SPELL_ID in $(cat "wow_secret_AURA_ALWAYS_SECRET_sorted_$DATE.txt"); do
			echo "\t[$SPELL_ID] = true,"
		done
	fi

	echo "};"
	echo ""
	echo "VUHDO_SPELL_AURA_NEVER_SECRET = {"

	if [ -s "wow_secret_AURA_NEVER_SECRET_sorted_$DATE.txt" ]; then
		for SPELL_ID in $(cat "wow_secret_AURA_NEVER_SECRET_sorted_$DATE.txt"); do
			echo "\t[$SPELL_ID] = true,"
		done
	fi

	echo "};"
	echo ""
	echo "VUHDO_SPELL_COOLDOWN_ALWAYS_SECRET = {"

	if [ -s "wow_secret_COOLDOWN_ALWAYS_SECRET_sorted_$DATE.txt" ]; then
		for SPELL_ID in $(cat "wow_secret_COOLDOWN_ALWAYS_SECRET_sorted_$DATE.txt"); do
			echo "\t[$SPELL_ID] = true,"
		done
	fi

	echo "};"
	echo ""
	echo "VUHDO_SPELL_COOLDOWN_NEVER_SECRET = {"

	if [ -s "wow_secret_COOLDOWN_NEVER_SECRET_sorted_$DATE.txt" ]; then
		for SPELL_ID in $(cat "wow_secret_COOLDOWN_NEVER_SECRET_sorted_$DATE.txt"); do
			echo "\t[$SPELL_ID] = true,"
		done
	fi

	echo "};"
} > "$OUTFILE"

rm -f wow_db2_spellmisc_$DATE.csv
rm -f wow_secret_CAST_ALWAYS_SECRET_$DATE.txt
rm -f wow_secret_CAST_ALWAYS_SECRET_sorted_$DATE.txt
rm -f wow_secret_CAST_NEVER_SECRET_$DATE.txt
rm -f wow_secret_CAST_NEVER_SECRET_sorted_$DATE.txt
rm -f wow_secret_AURA_ALWAYS_SECRET_$DATE.txt
rm -f wow_secret_AURA_ALWAYS_SECRET_sorted_$DATE.txt
rm -f wow_secret_AURA_NEVER_SECRET_$DATE.txt
rm -f wow_secret_AURA_NEVER_SECRET_sorted_$DATE.txt
rm -f wow_secret_COOLDOWN_ALWAYS_SECRET_$DATE.txt
rm -f wow_secret_COOLDOWN_ALWAYS_SECRET_sorted_$DATE.txt
rm -f wow_secret_COOLDOWN_NEVER_SECRET_$DATE.txt
rm -f wow_secret_COOLDOWN_NEVER_SECRET_sorted_$DATE.txt

echo "Complete."

exit 0