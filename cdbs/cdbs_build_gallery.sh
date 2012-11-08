#!/bin/bash -vx
#
# cdbs_build_gallery.sh (Sat,  5 Aug 2006 22:16:22 -0300)
#
# Build a gallery with all CDBS rules used in the whole Debian archive
# Copyright 2006 Caio Begotti <caio@ueberalles.net>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# remove the hashes in the line below to make it quiet
# # # # # # # # # # # # # # # # # # # # # VERBOSE=OFF

unalias apt-get

# script's paths
BaseDir=$(pwd)
LocalApt="${BaseDir}/archive"

# apt's and script dirs
DirCache=${LocalApt}/cache
DirLists=${LocalApt}/lists
DirState=${LocalApt}/state
DirBuild=${LocalApt}/build
DirRules=${LocalApt}/rules
DirOutput=${LocalApt}/site
DirTemp=${LocalApt}/temp

# all options of our 'static' apt
AptOptions="-o Dir::Etc::SourceList=${LocalApt}/sources.list \
            -o Dir::State::Lists=${DirLists}                 \
            -o Dir::State=${DirState}                        \
            -o Debug::NoLocking=true"

# sources.list config
MirrorVersion="unstable"
MirrorPaths="main contrib non-free"
MirrorURL="file:$(pwd)/../mirror/debian"

# if you want to specify more than just one mirror, use \n
AptMirror="deb-src ${MirrorURL} ${MirrorVersion} ${MirrorPaths}"

# packages to parse and work out
PackageList=${LocalApt}/packages.list

function func_logging()
{
	if [ ! "${VERBOSE}" == "OFF" ]
	then
		echo -e "${1}"
	fi
}

function func_build_tree()
{
	for Dir in ${DirCache} ${DirState} ${DirBuild} ${DirRules} ${DirOutput} ${DirTemp} ${DirLists} ${DirLists}/partial
	do
		test -d ${Dir} || mkdir -p ${Dir}
	done
}

function func_clean_up()
{
	rm -rf ${LocalApt}/*
	func_build_tree
}

function func_update_sources()
{
	echo ${AptMirror} > ${LocalApt}/sources.list
	apt-get --allow-unauthenticated -qq -y --force-yes ${AptOptions} update
	grep -B 10 cdbs ${DirLists}/*_source_* | sed '/Package/!d;s/^.*: //g;/\@/d' | grep -v ^$ | sort -n > ${PackageList}
}

function func_download_sources()
{
	if [ ! -s ${PackageList} ]; then
		func_logging "Package list ${PackageList} is empty, aborting"
		exit 1
	fi

	while read Current
	do
		cd ${DirCache}
		func_logging "${Current}..."
	
		apt-get --allow-unauthenticated -qq -y --force-yes ${AptOptions} update
		apt-get --allow-unauthenticated -qq ${AptOptions} -y --force-yes source ${Current}
	
	done < ${PackageList}
}

function func_copy_stuff()
{
	CurName=${1}
	CurDir=${2}

	cp -a ${DirCache}/${CurDir}/debian ${DirBuild}/${CurName}
	cp -a ${DirBuild}/${CurName}/rules ${DirRules}/${CurName}.sh

	# which ones and how many packages this debian/rules files builds?
	sed '/^Package:/!d;s/^.*: //g' ${DirBuild}/${CurName}/control > ${DirTemp}/packages.${CurName}
	sed '/^Description:/!d;s/^.*: //g' ${DirBuild}/${CurName}/control > ${DirTemp}/descriptions.${CurName}

	paste -d¬ ${DirTemp}/packages.${CurName} ${DirTemp}/descriptions.${CurName} | sort | tr [[:upper:]] [[:lower:]] > ${DirTemp}/resources.${CurName}
}

function func_highlight()
{
	Current=${1}

	# variables with any declaration type (like := or +=)
	sed -i  -e '/^[[:blank:]]\?\+[[:alpha:]].*\ \?[:+]\?=/s/=\ \+\?/=<\/span> /' \
		-e '/^[[:blank:]]\+\?[[:alpha:]].*\ \?[:+]\?=/s/^/<span class\=\"variable\">/' ${DirRules}/${Current}.sh

	# highlight maintainer's comments, wherever in the file
	sed -i  -e '/^[[:blank:]]\+\?#.*$/s/^/<span class\=\"comment\">/' \
		-e '//s/$/<\/span>/' ${DirRules}/${Current}.sh

	# for make commands (cp, rm, touch, debhelper etc)
	sed -i  -e '/^\t/s/^/\t<span class\=\"command\">/' \
		-e '//s/$/<\/span>/' ${DirRules}/${Current}.sh

	# match targets (depends on the variable filter)
	sed -i  -e '/^[^<].\?[[:alnum:]].*[[:alnum:]]\ \?::\?/s/^/<span class\=\"target\">/' \
		-e '//s/$/<\/span>/' ${DirRules}/${Current}.sh

	# include entries (external or internal source)
	sed -i  -e '/^include.*\.m\?.*$/s/^/<span class\=\"include\">/' \
		-e '//s/$/<\/span>/' ${DirRules}/${Current}.sh

	# any other kind of rules
	sed -i  -e '/^[[:alnum:]]\+\/.*: /s/^/<span class\=\"rule\">/' \
		-e '//s/$/<\/span>/' ${DirRules}/${Current}.sh
}

function func_include_ref()
{
	Current=${1}

	sed '/^include.*\.m\?.*$/!d' ${DirBuild}/${Current}/rules | cut -d" " -f2 > ${DirTemp}/${Current}.ref

	while read Include
	do
		IncName=$(basename ${Include})
		if grep -q ${IncName} ${IncList}
		then
			echo -e "\t<p><a href=\""${Current}.html"\">${Current}</a></p>" >> ${DirTemp}/_${IncName}.html.tmp
		fi

	done < ${DirTemp}/${Current}.ref
}

function func_template_build()
{
	Current=${1}

	sed "s/CURRENT_SOURCE/${Current}/g" ${BaseDir}/template/_template.html > ${DirTemp}/${Current}.html

	while read Deb
	do
		BuildName=$(echo ${Deb} | cut -d¬ -f1)
		BuildDesc=$(echo ${Deb} | cut -d¬ -f2)

		# this URL shows detailed information about each binary package in p.d.o
		BuildURL="http://packages.debian.org/search?keywords=${BuildName}&searchon=names&suite=${MirrorVersion}&section=all"

		echo -e "<dt>\n\t<a href='${BuildURL}'>${BuildName}</a>\n\t<dd>${BuildDesc}</dd>\n</dt>" >> ${DirTemp}/buildlist.${Current}

	done < ${DirTemp}/resources.${Current}

	func_include_ref ${Current}
	func_highlight ${Current}

	sed -i  -e "/CURRENT_BUILD_LIST/r ${DirTemp}/buildlist.${Current}" \
		-e "/CURRENT_BUILD_LIST/d"	${DirTemp}/${Current}.html

	sed -i  -e "/CURRENT_RULES/r ${DirRules}/${Current}.sh"	\
		-e "/CURRENT_RULES/d"		${DirTemp}/${Current}.html

	cp ${DirTemp}/${Current}.html ${DirOutput}/${Current}.html
	echo "<p><a href=\""${Current}.html"\">${Current}</a></p>" >> ${DirTemp}/_packages.html
}

function func_index_generate()
{
	for Letter in {{a..z},{0..9}}
	do
		grep "href=\"${Letter}.*$" ${DirTemp}/_packages.html > ${DirTemp}/_${Letter}.packages.html

        	sed "/CURRENT_FILENAME/r ${DirTemp}/_${Letter}.packages.html" ${BaseDir}/template/_packages.html > ${DirOutput}/_list.${Letter}.html

	        sed -i "/CURRENT_FILENAME/d" ${DirOutput}/_list.${Letter}.html
		sed -i "s/CURRENT_LETTER/${Letter}/" ${DirOutput}/_list.${Letter}.html
	done

	UpdateTime=$(date -R)
	MinAmount=$(find ${DirRules}/ | grep .sh$ | wc -l)
	MaxAmount=$(cat ${DirLists}/*_source_* | sed '/Package/!d;s/^.*: //g' | wc -l)
	CutAmount=$(echo $(((${MinAmount}*100)/${MaxAmount})))

	cp ${BaseDir}/template/index.html ${DirOutput}/

	sed -i  -e "s/MAX_OUTPUT/${MaxAmount}/" \
		-e "s/MIN_OUTPUT/${MinAmount}/"	\
		-e "s/CUT_OUTPUT/${CutAmount}/" \
		-e "s/DATE_OUTPUT/${UpdateTime}/" ${DirOutput}/index.html
}

clear

func_logging 'Erasing all the data fetched, processed and temp files. \nThis may take some time, so please be patient.\n'
func_clean_up

# official cdbs includes
IncList=${LocalApt}/includes.list
rm -rf build-common && git clone git://git.debian.org/collab-maint/cdbs.git build-common
find build-common/1 -type f | grep -v .git | sed 's/\.in$//g' > ${IncList}
if [ ! -e ${IncList} ]; then
	func_logging "CDBS includes list ${IncList} not present, aborting"
	exit 1
fi

func_logging "Updating APT sources (${LocalApt}/sources.list)."
func_update_sources

func_logging '\nCheck & fetch the newest version of the following packages:\n'
func_download_sources

func_logging '\nProcessing the data files of the following packages:\n'

cd ${DirCache}

for Dir in $(find ./ -maxdepth 1 -type d | grep -v './$\|.git' | sort)
do
	SourceDir=$(basename ${Dir})
	SourceName=$(sed '/^Source:/!d;s/^.*: //' ${SourceDir}/debian/control)

	func_logging "${SourceName} ..."
	func_copy_stuff ${SourceName} ${SourceDir}

	func_template_build ${SourceName}
done

func_logging '\nIndexing all the pages created and finishing the whole automation!\n'
func_index_generate

for File in $(find ${BaseDir}/template/ -maxdepth 1 -type f | grep -v "index\|list\|packages\|includes\|template\.")
do
	cp ${File} ${DirOutput}/
done

while read File
do
	BaseName=$(basename ${File})
	test -e ${DirTemp}/_${BaseName}.html.tmp && echo -e "\t<p id=\"sorting\"><a href=\"_"${BaseName}.html"\">${BaseName}</a></p>" >> ${DirTemp}/_inctemp.html

done < ${IncList}

sort -u ${DirTemp}/_inctemp.html > ${DirTemp}/_includes.html
sed "/INCLUDES_LIST/r ${DirTemp}/_includes.html" ${BaseDir}/template/_list.html | sed "/INCLUDES_LIST/d" > ${DirOutput}/_list.html

for File in ${DirTemp}/_*.mk.html.tmp
do
	BaseName=$(basename ${File} | sed 's/.tmp$//')
	NameUniq=$(echo ${BaseName} | sed 's/.html//;s/_//')
	LinkItem="$(grep /${NameUniq}.in ${IncList})"
	LinkPath="$(echo ${LinkItem} | sed "s|build-common/|http://svn.debian.org/wsvn/build-common/trunk/|")"

	sed "/INCLUDE_PACKAGES/r ${File}" ${BaseDir}/template/_includes.html | sed "/INCLUDE_PACKAGES/d" > ${DirOutput}/${BaseName}
	sed -i "s/INCLUDE_NAME/$(echo ${BaseName%.html} | sed 's/_//g')/g" ${DirOutput}/${BaseName}
done

exit 0
