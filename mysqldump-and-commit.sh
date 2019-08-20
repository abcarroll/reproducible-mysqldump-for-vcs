#!/bin/bash

#
# reproducible-mysqldump-for-vs
# You WILL need the mysqldump(7) manual for this
# -----
# (C) Copyright A.B. Carroll <ben@hl9.net>; MIT License

# You need to define user/pass in a my.cnf file
# HOST="<ENTER YOUR HOST HERE!>" # (or use env)

# CUSTOM_OPTION="<YOUR CUSTOM OPTIONS HERE!>" # (or use env, or totally customize the script!)
# ex. CUSTOM_OPTION="--ignore-table=mydb.someview --blah"

# These options are passed to both XML and SQL.
# The only difference is XML's dump will have --xml added to it.
COMMON_OPTION="--log-error=error.log --skip-opt --force --no-data --quick --all-tablespaces --events --routines --triggers --skip-dump-date --allow-keywords --comments --complete-insert --create-options --disable-keys --hex-blob --set-charset --tz-utc" 

# The database you're targeting.
# DUMP_TARGET="mydb"

# Output files
SQL_FILE="full-schema.sql"
XML_FILE="full-schema.xml"

# All options put together entirely.
FULL_OPTION="-h ${HOST} ${COMMON_OPTION} ${CUSTOM_OPTION} ${DUMP_TARGET}"

# Defaults.  You can for example turn off git entirely by setting it to 0 here.
PERFORM_DUMP_SQL=1
PERFORM_DUMP_XML=1
PERFORM_GIT=1

## Mostly everything below this line isn't as easily modified.
## But feel free!
# ---------------------

# Usage 
function usage() { 
	echo ""
	echo " A.B. Carroll <ben@hl9.net>; MIT License"
	echo " https://github.com/abcarroll/reproducible-mysqldump-for-vcs"
	echo ""
	echo "Available options:"
	echo " --help                This text you're reading now"
	echo " --skip-sql            Don't dump SQL file."
	echo " --skip-xml            Don't dump XML file."
	echo " --skip-git            Don't perform a commit/push"
}

# Parse args
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --skip-sql)
            PERFORM_DUMP_SQL=0
            ;;
        --skip-xml)
            PERFORM_DUMP_SQL=0
            ;;
        --skip-git)
            PERFORM_GIT=0
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

# A couple of simple funcs
function get_cksum() { 
	FILE=$1
	echo $(cat "${FILE}" | sha256sum | cut -d ' ' -f1);
}

function get_lcnt() {
	FILE=$1
	echo $(cat "${FILE}" | wc -l);
}

function generate()
{
	WORK_FILE="$1"
	OUTPUT_FILE="$2"
	fname=$(basename "${WORK_FILE}");
	echo "[$fname] ---------------------------------------"
	echo "[$fname] Target File:   ${WORK_FILE}"
	echo "[$fname]   Temp File:   ${OUTPUT_FILE}"

	PREV_CKSM=$(get_cksum "${WORK_FILE}");
	PREV_LCNT=$(get_lcnt "${WORK_FILE}");
	echo "[$fname] Pre-Checksum:  ${PREV_CKSM}"
	echo "[$fname] Pre-LineCount: ${PREV_LCNT}"

	mysqldump ${FULL_OPTION} > "${OUTPUT_FILE}"
}

function post_stats()
{
	WORK_FILE="$1"
	fname=$(basename "${WORK_FILE}");

	NEW_CKSM=$(get_cksum "${WORK_FILE}");
	NEW_LCNT=$(get_lcnt "${WORK_FILE}");
	echo "[$fname] New Checksum:  ${NEW_CKSM}"
	echo "[$fname] New LineCount: ${NEW_LCNT}"

	echo "[$fname] ---------------------------------------"
}

function clean_up()
{	
	WORK_FILE="$1"
	TMP_FILE="$2"
	post_stats "${WORK_FILE}" "${TMP_FILE}"
	rm "${TMP_FILE}"
}

# -----------------------------------------------------------------------------
# SQL
# -----------------------------------------------------------------------------
WORK_FILE="${SQL_FILE}"
TMP_FILE="tmp.${WORK_FILE}"
if [ "${PERFORM_DUMP_SQL}" -eq 1 ]; then
	generate "${WORK_FILE}" "${TMP_FILE}" 
	perl -p -e 's/(\).+?AUTO_INCREMENT)=\d+(.*?;\s+)/$1=-1$2/ig' "${TMP_FILE}" > "${WORK_FILE}"
	clean_up "${WORK_FILE}" "${TMP_FILE}" 
fi;
echo ""
# -----------------------------------------------------------------------------
# XML
# -----------------------------------------------------------------------------
WORK_FILE="${XML_FILE}"
TMP_FILE="tmp.${WORK_FILE}"
if [ "${PERFORM_DUMP_XML}" -eq 1 ]; then
	FULL_OPTION="--xml ${FULL_OPTION}" # watch this line!
	generate "${WORK_FILE}" "${TMP_FILE}"
	perl -p -e 's/(\s*)(cardinality)="\d+"(\s+)/$1$2="-1"$3/ig if /^\s+\<key\s+.+/i; s/(\s*)(rows|avg_row_length|avg_row_length|data_length|index_length|data_free|auto_increment)="\d+"(\s+)/$1$2="-1"$3/ig if /^\s+\<options\s+.+/i' "${TMP_FILE}" > "${WORK_FILE}"
	clean_up "${WORK_FILE}" "${TMP_FILE}" 
fi;

if [ "${PERFORM_GIT}" -eq 1 ]; then
	DATE=$(date -R)
	GITMSG="Automated commit on ${DATE}\n"
	git add .
	git commit -m "${GITMSG}"
fi;

