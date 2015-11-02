#!/bin/bash

# Hyeongwan Seo

# [주의]
# 1. write 테스트할 때는 드라이브가 모두 초기화 되므로 주의해야 합니다.
# 2. 값이 제대로 출력되지 않는다면, 시스템 환경에 맞게 sed 옵션을 수정해야 함.

DD_ORIGINAL_RESULT_FILE=dd_original_result.txt
TRIMMED_RESULT_FILE=benchmark_result.txt
SUM_TIME_ALL=0
AVERAGE_BANDWIDTH=0
SUM_BANDWIDTH_ALL=0
AVERAGE_TIME_ALL=0
AVERAGE_TIME=0
OPERATION_TYPE=$1 	# read or write

YOUR_DISK_NAME=$2
NUM_ITERATION=$3

if [ $# -ne 3 ]
then
	echo -e "\e[1;31mUsage: ./read.sh read[또는 write] '드라이브 이름' '속도 측정 반복 횟수'\e[0m"
	echo -e "\e[1;31mExample: ./read.sh read[write] sda 10\e[0m\n"
	exit
fi

Init()
{
	echo -e "이 프로그램은 dd 명령어를 이용해서 HDD의 read 또는 write 속도를 측정합니다.\n"
	touch $DD_ORIGINAL_RESULT_FILE
	touch $TRIMMED_RESULT_FILE
	echo -e "\n\n---" >> $TRIMMED_RESULT_FILE

	date >> $TRIMMED_RESULT_FILE

	echo -e "\n MB/sec \t Time(s)" >> $TRIMMED_RESULT_FILE
	echo -e "====================" >> $TRIMMED_RESULT_FILE

}

Run()
{
	case "$OPERATION_TYPE" in
		"read")
			echo -e "read 속도 측정 중"
	 		dd if=/dev/$YOUR_DISK_NAME of=/dev/null bs=32k count=32000 2> $DD_ORIGINAL_RESULT_FILE;;
		"write")
			echo -e "write 속도 측정 중"
	 		#dd if=/dev/zero of=/dev/$YOUR_DISK_NAME bs=32k count=32000 2> $DD_ORIGINAL_RESULT_FILE;;
	esac

	# 값이 제대로 출력되지 않는다면, 시스템 환경에 맞게 sed 옵션을 수정해야 함.
	bandwidth[$NUM_ITERATION]=`cat $DD_ORIGINAL_RESULT_FILE | grep -o '[0-9.0-9]*' | sed -e '1,7d;9,$d'`
	time[$NUM_ITERATION]=`cat $DD_ORIGINAL_RESULT_FILE | grep -o '[0-9.0-9]*' | sed -e '1,6d;8,$d'`

    SUM_BANDWIDTH_ALL=`echo "$SUM_BANDWIDTH_ALL  ${bandwidth[$NUM_ITERATION]}" | awk '{print $1+$2}'`
	SUM_TIME_ALL=`echo "$SUM_TIME_ALL ${time[$NUM_ITERATION]}" | awk '{print $1+$2}'`
	
	sh -c "sync && echo 3 > /proc/sys/vm/drop_caches" 	# Buffer clear

	echo -e "${bandwidth[$NUM_ITERATION]} \t ${time[$NUM_ITERATION]}" >> $TRIMMED_RESULT_FILE   # Print contents

	rm -rf $DD_ORIGINAL_RESULT_FILE
}

Average()
{
    AVERAGE_BANDWIDTH=`echo "$SUM_BANDWIDTH_ALL $NUM_ITERATION" | awk '{print $1/$2}'`
 	echo -e "\n\nAverage Bandwidth = $AVERAGE_BANDWIDTH (MB/s)" >> $TRIMMED_RESULT_FILE
 	echo -e "\n\nAverage Bandwidth = $AVERAGE_BANDWIDTH (MB/s)" 				

	AVERAGE_TIME=`echo "$SUM_TIME_ALL $NUM_ITERATION" | awk '{print $1/$2}'`
	echo -e "Average Time = $AVERAGE_TIME (s)\n" >> $TRIMMED_RESULT_FILE
	echo -e "Average Time = $AVERAGE_TIME (s)\n" 							
}

Init

for((i=0;i<$NUM_ITERATION;i++))
do
	Run
	
done

Average
echo -e "[\e[1;32mSuccess!\e[0m] 반복 횟수별 디스크 속도는 $TRIMMED_RESULT_FILE 파일에 기록되어 있습니다."
