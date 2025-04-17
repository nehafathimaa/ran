#!/bin/bash

DATE=$(date +%d%b%Y-%H-%M-%S)
wc_installlogdir=/opt/WebSphere/CommerceServer90/logs
LOG_FILE=$wc_installlogdir/msds_import.log
COVEO_LOG_FILE=$wc_installlogdir/coveo_msds.log
impex_bin=/apps/Config/data/bin

export JAVA_HOME=/opt/WebSphere/AppServer/java/8.0
export PATH=$JAVA_HOME/bin:$PATH

str_list=`grep -i "config.msds.stores" $impex_bin/../config/config.properties | cut -d '=' -f 2`

storname=( $(echo $str_list | sed "s/,/ /g") )

umask 0017

touch $LOG_FILE
touch $COVEO_LOG_FILE

for store in "${storname[@]}"; do
                echo -e "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
                echo -e "*** Start import msds dataload for $store"
                $impex_bin/impex.sh import_MSDS $store >> $LOG_FILE
                echo -e "*** END import msds for $store"
                echo -e "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
                sleep 5
done

zip $wc_installlogdir/msds_import_$DATE.zip $LOG_FILE
rm $LOG_FILE
find $wc_installlogdir -maxdepth 2 -type f -mtime +7 \( -name "*??.log" -o -name "*??.zip" -o -name "*.log-??*" \) -delete

umask 0027

Coveo_stores=$(grep -i "^config.Coveo.stores=" "$impex_bin/../config/config.properties" | cut -d'=' -f2)
IFS=',' read -r -a coveo_stores <<< "$Coveo_stores"

CoveoExtractionMSDSFull(){
        for store in "${coveo_stores[@]}"; do
        echo "Running command for store: $store"
                echo ""
                echo -e "=-=-=-=-=-=-="
                echo -e "***  Coveo full MSDS extraction...\n\n\t$store"
                echo -e "\n\n"
                echo "Start Time - $(date +%Y-%m-%d_%H:%M)"
                stime=$(date +%s)
                $impex_bin/impex.sh fullindex $store MSDS >> $COVEO_LOG_FILE
                etime=$(date +%s)
                echo "Start Time - $(date +%Y-%m-%d_%H:%M)"
                diff=$(($etime-$stime))
                echo "$dat_time,$store,difference..,$diff"
                sleep 10
                echo -e "\n\n"
                echo -e "*** END of Coveo extraction on MSDS for Full Indexing ...\n\t$store"
                echo ""
                echo "done."
                END_TIME=$(date +%Y-%m-%d_%H:%M)
                echo $END_TIME
                echo "-=-=-=-=-=-=-=-=-=-=-=-"
        done
        echo "End of Coveo extraction for all stores with MSDS FullIndex"
        echo "End Time - $(date +%Y-%m-%d_%H:%M)"
}
CoveoIndexingMSDSfull(){
        for store in "${coveo_stores[@]}"; do
        echo "Running command for store: $store"
                echo ""
                echo -e "=-=-=-=-=-=-="
                echo -e "***  Coveo Indexing for Datasheets,MSDS,full ...\n\n\t$store"
                echo -e "\n\n"
                echo "Start Time - $(date +%Y-%m-%d_%H:%M)"
                stime=$(date +%s)
                $impex_bin/impex.sh coveoindex $store Datasheets,MSDS,full >> $COVEO_LOG_FILE
                etime=$(date +%s)
                echo "Start Time - $(date +%Y-%m-%d_%H:%M)"
                diff=$(($etime-$stime))
                echo "$dat_time,$store,difference,$diff"
                sleep 10
                echo -e "\n\n"
                echo -e "*** END of Coveo Indexing for Datasheets,MSDS,full...\n\t$store"
                echo ""
                echo "done."
                END_TIME=$(date +%Y-%m-%d_%H:%M)
                echo $END_TIME
                echo "-=-=-=-=-=-=-=-=-=-=-=-"
        done
        echo "End Coveo indexing for all the stores with Datasheets,MSDS,full..."
        echo "End Time - $(date +%Y-%m-%d_%H:%M)"
}
CoveoIndexingMSDSdelta(){
        for store in "${coveo_stores[@]}"; do
        echo "Running command for store: $store"
                echo ""
                echo -e "=-=-=-=-=-=-="
                echo -e "***  Coveo Indexing for Datasheets,MSDS,delta...\n\n\t$store"
                echo -e "\n\n"
                echo "Start Time - $(date +%Y-%m-%d_%H:%M)"
                stime=$(date +%s)
                $impex_bin/impex.sh coveoindex $store Datasheets,MSDS,delta >> $COVEO_LOG_FILE
                etime=$(date +%s)
                echo "Start Time - $(date +%Y-%m-%d_%H:%M)"
                diff=$(($etime-$stime))
                echo "$dat_time,$store,difference,$diff"
                sleep 10
                echo -e "\n\n"
                echo -e "*** END of Coveo Indexing for Datasheets,MSDS,delta...\n\t$store"
                echo ""
                echo "done."
                END_TIME=$(date +%Y-%m-%d_%H:%M)
                echo $END_TIME
                echo "-=-=-=-=-=-=-=-=-=-=-=-"
        done
        echo "End Coveo indexing for all the stores with Datasheets,MSDS,delta..."
        echo "End Time - $(date +%Y-%m-%d_%H:%M)"
}
CoveoExtractionMSDSFull
if [[ $(date +%u) -eq 7 ]]; then
        CoveoIndexingMSDSfull
else
        CoveoIndexingMSDSdelta
fi

zip $wc_installlogdir/msds_import_coveo_$DATE.zip $COVEO_LOG_FILE
rm $COVEO_LOG_FILE
find $wc_installlogdir -maxdepth 2 -type f -mtime +7 \( -name "*??.log" -o -name "*??.zip" -o -name "*.log-??*" \) -delete

umask 0027
exit 0
