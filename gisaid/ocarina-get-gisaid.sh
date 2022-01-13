#!/usr/bin/bash

source ~/.bootstrap.sh
source "$EAGLEOWL_CONF/paths.env"
PATH=$PATH:$ELAN_BIN_DIR:$COGPUSH_GISAID_BIN_DIR
source "$EAGLEOWL_CONF/service_outbound.env"

set -euo pipefail
DATESTAMP=$1
BEFORE_DATESTAMP=$2
ocarina --env --oauth get pag --test-name 'cog-uk-high-quality-public' --pass --private --service-name GISAID --task-wait --task-wait-attempts 30 --odelimiter , --published-before $BEFORE_DATESTAMP \
    --ffield-true owner_org_gisaid_opted \
    --ofield central_sample_id central_sample_id 'XXX' \
    --ofield adm1_trans adm1_trans 'XXX' \
    --ofield received_date received_date 'XXX' \
    --ofield published_name pag_name 'XXX' \
    --ofield collection_date collection_date 'XXX' \
    --ofield owner_org_gisaid_user submitter 'XXX' \
    --ofield consensus.current_path climb_fn 'XXX' \
    --ofield - fn $DATESTAMP.gisaid.fa \
    --ofield - covv_virus_name '' \
    --ofield - covv_type betacoronavirus \
    --ofield - covv_passage Original \
    --ofield - covv_collection_date '' \
    --ofield '~Europe / {adm0} / {adm1_trans}' covv_location 'XXX' \
    --ofield - covv_add_location ' ' \
    --ofield - covv_host Human \
    --ofield - covv_add_host_info ' ' \
    --ofield - covv_gender 'unknown' \
    --ofield - covv_patient_age 'unknown' \
    --ofield - covv_patient_status 'unknown' \
    --ofield - covv_specimen '' \
    --ofield - covv_outbreak '' \
    --ofield - covv_last_vaccinated '' \
    --ofield - covv_treatment '' \
    --ofield instrument_make covv_seq_technology 'XXX' \
    --ofield - covv_assembly_method '' \
    --ofield - covv_coverage '' \
    --ofield credit_lab_name covv_orig_lab 'XXX' \
    --ofield credit_lab_addr covv_orig_lab_addr 'XXX' \
    --ofield central_sample_id covv_provider_sample_id '' \
    --ofield - covv_subm_lab 'COVID-19 Genomics UK (COG-UK) Consortium' \
    --ofield - covv_subm_lab_addr 'United Kingdom' \
    --ofield central_sample_id covv_subm_sample_id 'XXX' \
    --ofield credit_lab_list covv_authors 'XXX' 2> err | csvsort -c 'central_sample_id' > $DATESTAMP.csv

make_covv_name.py $DATESTAMP.csv > $DATESTAMP.covv.csv
rm $DATESTAMP.csv

csvcut -c climb_fn,covv_virus_name $DATESTAMP.covv.csv | csvformat -T | sed 1d > $DATESTAMP.ls
echo "Unique FASTA inputs" `cut -f1 $DATESTAMP.ls | sort | uniq | wc -l`

remove_ls_dups_for_now.py $DATESTAMP.ls $DATESTAMP.undup.ls $DATESTAMP.covv.csv $DATESTAMP.undup.csv 2> $DATESTAMP.undup.log

rm -f $DATESTAMP.gisaid.fa

IFS=$'\t'; while read fn header;
do
    elan_rehead.py $fn $header >> $DATESTAMP.gisaid.fa;
done < $DATESTAMP.undup.ls

echo "Unique sequences output to FASTA" `grep '^>' $DATESTAMP.gisaid.fa | sort | uniq | wc -l`

csvcut -C collection_date,received_date,adm1_trans,central_sample_id,pag_name,climb_fn $DATESTAMP.undup.csv > $DATESTAMP.gisaid.csv
echo "Unique samples in GISAID metadata" `csvcut -c covv_subm_sample_id $DATESTAMP.gisaid.csv | sed 1d | wc -l`

cut -f1 -d',' $DATESTAMP.gisaid.csv | sort | uniq -c | grep -v 'submitter'
