#!/bin/bash

DATE=$(date +"%Y-%m-%d")

rm -r ~/cleanup_logs/$DATE
>~/cleanup_logs/last_run_log.txt
