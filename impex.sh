#!/bin/bash

## mail configuration for stagingImport:
MAILENABLE=@MMSIMPEXMAILENABLE@
MAILCONTACTS="@MMSIMPEXMAILCONTACTS@"
MAILCONTENT="@MMSIMPEXMAILCONTENT@"
ENVNAME=@MMSWCINSTANCE@
##
export JAVA_HOME=/opt/WebSphere/AppServer/java/8.0/
export ANT_HOME=/opt/WebSphere/CommerceServer90/wcbd/apache-ant-1.10.11

usage(){
        echo "$0            import                    <store name>"
        echo "$0            import_MSDS               <store name>"
        echo "$0            import_enrichment         <store name>"
        echo "$0            import_PIM_Integration    <store name>"
        echo "$0            propagate_flags           <store name>"
        echo "$0            capture_catalog_deletion  <store name>"
        echo "$0            export                    <store name>"
        echo "$0            exportCatalogue           <store name>"
        echo "$0            export_full               <store name>"
        echo "$0            export_DeltaIndexData     <store name>"
        echo "$0            delete_old_catalog_in_db  <store name>"
        echo "$0            delete_lock               <store name>"
        echo ""
        echo "$0            update_index              <store name>"
        echo ""
        echo "$0            update_index_delta              <store name>"
        echo ""
        echo "$0            stagingImport             <store name>"
        echo ""
        echo "$0            importMembers             <store name>"
        echo ""
        echo "$0            importMemberGroupMember   <store name>"
        echo ""
        echo "$0            importMemberGroupMemberReOrder   <store name>"
        echo ""
        echo "$0            importMemberWithAccounts   <store name>"
#       echo ""
        echo "$0            generate_seo_keywords     <store name>"
        echo "$0            checkStagepropTable       <store name>"
        echo ""
        echo "$0            crawling_stores               <store name>"
        echo ""
        echo ""
        echo "$0            invalidateCacheStage        <invalidation_time_in_milli_seconds>"
        echo "$0            invalidateCacheLive <invalidation_time_in_milli_seconds>"
        echo "$0            registryRefreshStage"
        echo "$0            registryRefreshLive"
        echo "$0            stgProp"
        echo "$0                        resourcebundleRefreshStage <store name>"
        echo "$0                        resourcebundleRefreshLive <store name>"
        echo "$0            copyStatistics"
        echo "$0            updateSlaves"
        echo "$0            redisCache"
        echo "$0            crawling_content"
        echo "$0            searchReplication"
        echo "$0            getsaptoshop"
        echo "$0            putshoptosap"
        echo "$0            putfullenrichtosap"
        echo "$0            getshoptosap"
        echo "$0            deletesaptoshop"
        echo "$0            fullindex <store name> <Catalog>, <PDS>, <Catalog,PDS>, <MSDS>"
        echo "$0            deltaindex <store name> <Catalog>, <PDS>, <Catalog,PDS>, <MSDS>"
        echo "$0            coveoindex <store name> <Catalog,full>,<Catalog,delta>,<Catalog,DELETE>,<Category>,<Locations>,<Datasheets,MSDS,full>, <Datasheets,MSDS,delta>,<Datasheets,PDS,full>,<Datasheets,PDS,delta>,<Datasheets,DELETE,full>,<MyAccount>,<FAQ>"
        echo ""
        echo "E.g.:"
        echo "$0 import AU_BOC_Industrial_Store"
        echo "$0 import UK_BOC_Industrial_Ntl_Store"
        exit 1
}



executeScript(){


    export CLASSPATH=${binDir}/../lib/ant-contrib-1.0b3.jar:${CLASSPATH}

        ${ANT_HOME}/bin/ant -f ${binDir}/../scripts/impex.xml ${mode} -Dimpex.store.name=${STORE} ${DELETEFILE} | tee -a ${LOGFILE} 2>&1
        RC=${PIPESTATUS[0]}
        if [ "${RC}" != "0" ] ; then
            echo "error executing impex.xml.."  | tee -a ${LOGFILE} 2>&1
            echo "see log: ${LOGFILE}"
                exit ${RC}
        fi

        echo "see log: ${LOGFILE}"
        echo "done execute script"
}


coveoData(){
        if [ "${mode}" == "fullindex" ] || [ "${mode}" == "deltaindex" ]; then
                ${ANT_HOME}/bin/ant -f ${binDir}/../scripts/impex.xml Coveo_extraction_main -Dmode=${mode} -DExtract_type=${Extract_type} -Dimpex.store.name=${STORE} | tee -a ${LOGFILE} 2>&1
                RC=${PIPESTATUS[0]}
                        if [ "${RC}" != "0" ] ; then
                                latest_log_file=$(ls -t ${binDir}/../CatalogImport/_log/CoveoExtract_* | head -n 1)
                        echo "coveo extraction failed. Please find the attached log file." | mail -s "Coveo Extraction Failed" -a "${latest_log_file}" Valtech-Azure-AO@valtech.com
                        echo "error coveo target..."  | tee -a ${LOGFILE} 2>&1
                        echo "see log: ${LOGFILE}"
                                exit ${RC}
                        fi
                echo "see log: ${LOGFILE}"
                echo "done execute script"
        elif [ "${mode}" == "coveoindex" ]; then
                ${ANT_HOME}/bin/ant -f ${binDir}/../scripts/impex.xml Coveo_Indexing_main -DExtract_type=${Extract_type} -Dimpex.store.name=${STORE} | tee -a ${LOGFILE} 2>&1
                RC=${PIPESTATUS[0]}
                if [ "${RC}" != "0" ] ; then
                        latest_log_file=$(ls -t ${binDir}/../CatalogImport/_log/CoveoIndexing_* | head -n 1)
                echo "coveo indexing failed. Please find the attached log file." | mail -s "Coveo Indexing Failed" -a "${latest_log_file}" Valtech-Azure-AO@valtech.com
                echo "error coveo target..."  | tee -a ${LOGFILE} 2>&1
                echo "see log: ${LOGFILE}"
                        exit ${RC}
                fi
                echo "see log: ${LOGFILE}"
                echo "done execute script"
        fi
}

checkMail(){
        RC=$1

        echo "RC=${RC}" | tee -a ${LOGFILE} 2>&1
        if [ "${RC}" != "0" ] ; then
            echo "error executing impex.xml.." | tee -a ${LOGFILE} 2>&1
            echo "log file @${LOGFILE}" | tee -a ${LOGFILE} 2>&1
                if [ "true" = "${MAILENABLE}" ] ; then
                        echo "sending error mail to ${MAILCONTACTS}.." | tee -a ${LOGFILE} 2>&1
                        tail -n50 ${LOGFILE} | mail -s "[${ENVNAME}] ERROR in ${mode} for ${STORE} (RC=${RC})" ${MAILCONTACTS}
                fi
                exit ${RC}
        fi
}


stagingImport(){

        export CLASSPATH=${binDir}/../lib/ant-contrib-1.0b3.jar:${CLASSPATH}
        export CLASSPATH=${binDir}/../lib/jsch-0.1.44.jar:${CLASSPATH}

        echo "## start import for store ${STORE}.." | tee -a ${LOGFILE} 2>&1
        echo "####################################" | tee -a ${LOGFILE} 2>&1

        ${ANT_HOME}/bin/ant -f ${binDir}/../scripts/impex.xml ${mode} -Dimpex.store.name=${STORE} -Dimpex.sysout.log=${LOGFILE}
        checkMail ${PIPESTATUS[0]}

        echo "log file @${LOGFILE}"
        echo "##done" | tee -a ${LOGFILE} 2>&1
}


executeSiteScript(){

        export CLASSPATH=${binDir}/../lib/ant-contrib-1.0b3.jar:${CLASSPATH}
        export CLASSPATH=${binDir}/../lib/jsch-0.1.44.jar:${CLASSPATH}

        ${ANT_HOME}/bin/ant -f ${binDir}/../scripts/impex.xml ${mode} | tee -a ${LOGFILE} 2>&1
        checkMail ${PIPESTATUS[0]}

        echo "log file @${LOGFILE}"
        echo "##done" | tee -a ${LOGFILE} 2>&1
}

executeCacheInvalidationScript(){

        export CLASSPATH=${binDir}/../lib/ant-contrib-1.0b3.jar:${CLASSPATH}
        export CLASSPATH=${binDir}/../lib/jsch-0.1.44.jar:${CLASSPATH}


        ${ANT_HOME}/bin/ant -f ${binDir}/../scripts/impex.xml ${mode} -Dtime.milli.seconds=${STORE} | tee -a ${LOGFILE} 2>&1
        checkMail ${PIPESTATUS[0]}

        echo "log file @${LOGFILE}"
        echo "##done" | tee -a ${LOGFILE} 2>&1
}

#Global Properties:
USED_AWK=/usr/bin/awk
PLATFORM=`/bin/uname`
OSUSERNAME=`whoami`
echo "OSRunUser: ${OSUSERNAME}"
#Determine Home Directory from /etc/passwd
OSUSERNAMEHOMEDIR=`${USED_AWK} -F: '{ if ($1 == "'"$OSUSERNAME"'") print $6 }' /etc/passwd`

#USER_HOME=`getent passwd ${OSUSERNAME}`
#DCPOSUSERNAMEHOMEDIR=`echo $USER_HOME | grep -o -P '(?<=Owner:).*(?=:)'`

USER_HOME=`getent passwd  ${OSUSERNAME}`
DCPOSUSERNAMEHOMEDIR=`echo ${USER_HOME} | cut -d: -f6`

if [ -r $OSUSERNAMEHOMEDIR/.bash_profile ]; then
        echo "Load profile for user ${OSUSERNAME} ${OSUSERNAMEHOMEDIR}/.bash_profile .."
        . ${OSUSERNAMEHOMEDIR}/.bash_profile
elif [ -r $DCPOSUSERNAMEHOMEDIR/.bash_profile ]; then
        echo "Load profile for user ${OSUSERNAME} ${DCPOSUSERNAMEHOMEDIR}/.bash_profile .."
        . ${DCPOSUSERNAMEHOMEDIR}/.bash_profile
else
        echo "[ERROR] ${OSUSERNAMEHOMEDIR}/.profile does not exist!"
        exit 1
fi

binDir=`dirname "$0"`
pwd=`pwd`

if [ ${binDir} = "." ] ; then
        binDir=${pwd}
fi


mode=$1
DELETEFILE="-Ddelete_import_files=on_success_only"
TS=`date +%Y%m%d%H%M%S`
LOGFILE=${binDir}/../logs/impex-${mode}-${STORE}_${TS}.log



if [ "XX$2" = "XX" ]; then
        LOGFILE=${binDir}/../logs/impex-${mode}_${TS}.log
        case "${mode}" in
                copyStatistics)
                        executeSiteScript;;
                registryRefreshStage)
                        executeSiteScript;;
                registryRefreshLive)
                        executeSiteScript;;
                stgProp)
                        executeSiteScript;;
                getsaptoshop)
                        executeSiteScript;;
                putshoptosap)
                        executeSiteScript;;
                putfullenrichtosap)
                        executeSiteScript;;
                getshoptosap)
                        executeSiteScript;;
                deletesaptoshop)
                        executeSiteScript;;
                updateSlaves)
                        executeSiteScript;;
                redisCache)
                        executeSiteScript;;
                crawling_content)
                        executeSiteScript;;
                searchReplication)
                        executeSiteScript;;
                *)
                        usage
                        exit 1;;
        esac
elif [ "XX$3" = "XX" ]; then
        STORE=$2
        case "${mode}" in
                stagingImport)
                        stagingImport;;
                import_enrichment)
                        stagingImport;;
                import_PIM_Integration)
                        stagingImport;;
                import)
                        executeScript;;
                import_MSDS)
                        executeScript;;
                propagate_flags)
                        executeScript;;
                export)
                        executeScript;;
                exportCatalogue)
                        executeScript;;
                export_full)
                        executeScript;;
                exportDeltaIndexData)
                        executeScript;;
                delete_lock)
                        executeScript;;
                delete_old_catalog_in_db)
                        executeScript;;
                update_index)
                        executeScript;;
                update_index_delta)
                        executeScript;;
                importMemberGroupMember)
                        executeScript;;
                importMemberGroupMemberReOrder)
                        executeScript;;
                importMemberWithAccounts)
                        executeScript;;
                importMembers)
                        executeScript;;
                resourcebundleRefreshStage)
                        executeScript;;
                resourcebundleRefreshLive)
                        executeScript;;
                generate_seo_keywords)
                        executeScript;;
                checkStagepropTable)
                        executeScript;;
                crawling_stores)
                        executeScript;;
                invalidateCacheStage)
                        executeCacheInvalidationScript;;
                invalidateCacheLive)
                        executeCacheInvalidationScript;;
            capture_catalog_deletion)
                    executeScript;;
                *)
                        usage
                        exit 1;;
        esac
else
        STORE=$2
        Extract_type=$3
        case "${mode}" in
                fullindex)
                        coveoData;;
                deltaindex)
                        coveoData;;
                coveoindex)
                        coveoData;;
                *)
                        usage
                        exit 1;;
        esac

fi

echo "done all"
exit ${RC}
