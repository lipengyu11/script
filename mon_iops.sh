#!/bin/bash
#filename mysqlgather.sh
#param
#N seconds
#s print query
#t print transaction
#i print mysql io
# example
# ./mysqlgather.sh 20 s t i
#--脚本的名字为mysqlgather.sh,执行例子为 ./mysqlgather.sh 20 s t i
#其中20为取样的时间范围，在这里假设20s,这个时间参数必须要输入，时间大小可以自己定
#s 表示要统计query及query per second (可选参数)
#t 表示要统计transaction及transaction per second (可选参数)
#i 表示要统计mysql中的io请求数及io per second (可选参数)
#s t i 三个参数可以只输入其中任意一个或多个,可以只统计三个指标中的一个或者两个
#如果三个参数都写或者都不写，表示都要统计s t i
#--selecom函数取query数量
#qps
selcom ()
{
    mysql -uroot -e "show global status where variable_name in ('com_select');" > select.out
        SELECT_NUM=`grep -i "com_select" select.out | awk '{print $2}'`
            echo "com_select: $SELECT_NUM"
}
#--trans_num函数 统计transaction数量
#tps
trans_num ()
{
    mysql -uroot -pa -e "show global status where variable_name in('com_commit','com_rollback');" > transactions.out
        COMMIT_NUM=`grep -i "com_commit" transactions.out | awk '{print $2}'`
            ROLLBACK_NUM=`grep -i "com_rollback" transactions.out | awk '{print $2}'`
                SUM_TRAN=$[ $COMMIT_NUM1 + $ROLLBACK_NUM1 ]
                    echo "transations:$SUM_TRAN"
}
#--ionum函数统计io读写请求数
#IO
ionum ()
{
mysql -uroot -pa -e "show global status where variable_name in('Key_reads','Key_writes','Key_read_requests','Innodb_data_reads','Innodb_data_writes','Innodb_dblwr_writes','Innodb_log_writes');" > iops.out
KEYREAD=`grep -i "Key_reads" iops.out | awk '{print $2}'`
KEYWRITE=`grep -i "Key_writes" iops.out | awk '{print $2}'`
READREQ=`grep -i "Key_read_requests" iops.out | awk '{print $2}'`
DATAREAD=`grep -i "Innodb_data_reads" iops.out | awk '{print $2}'`
DATAWRITE=`grep -i "Innodb_data_writes" iops.out | awk '{print $2}'`
DBLWR=`grep -i "Innodb_dblwr_writes" iops.out | awk '{print $2}'`
LOGWRITE=`grep -i "Innodb_log_writes" iops.out | awk '{print $2}'`
SUM_IO=$[ $KEYREAD * 2 + $KEYWRITE * 2 + $READREQ + $DATAREAD + $DATAWRITE + $DBLWR + $LOGWRITE ]
echo "io:$SUM_IO"
}
#--up_time函数是统计MYSQL启动后的时间
#uptime
up_time ()
{
    mysql -uroot -pa -e "show global status where variable_name in ('Uptime');" > uptime.out
        UP_TIME=`grep -i "Uptime" uptime.out | awk '{print $2}'`
}
#--下面的程序逻辑是先检查输入了哪些参数，再计算所想要统计的指标
NUM_PARM=$#
if [ $NUM_PARM = 1 ];then
	PARM1=$1
	up_time
	UP_TIME1=$UP_TIME
	selcom
	SELECT_NUM1=$SELECT_NUM
	trans_num
	SUM_TRAN1=$SUM_TRAN
	ionum
	SUM_IO1=$SUM_IO
	sleep 1
	PARM1=$[ $PARM1 - 1]
	while [ $PARM1 -gt 0 ]
	do
		selcom
		trans_num
		ionum
		PARM1=$[ $PARM1 - 1]
		sleep 1
	done
	SELECT_NUM2=$SELECT_NUM
	SUM_TRAN2=$SUM_TRAN
	SUM_IO2=$SUM_IO
	up_time
	UP_TIME2=$UP_TIME
	#--统计时间范围内的总量
	SELECT_DIFF=$[ $SELECT_NUM2 - $SELECT_NUM1 ]
	TRANS_DIFF=$[ $SUM_TRAN2 - $SUM_TRAN1 ]
	IO_DIFF=$[ $SUM_IO2 - $SUM_IO1 ]
	TIME_DIFF=$[ $UP_TIME2 - $UP_TIME1 ]
	#--统计每秒的量
	SELECT_PERSECOND=$[ $SELECT_DIFF / $TIME_DIFF]
	TRANS_PERSECOND=$[ $TRANS_DIFF / $TIME_DIFF]
	IOREQ_PERSECOND=$[ $IO_DIFF / $TIME_DIFF]
	echo -n "sel_s:$SELECT_PERSECOND; trans_s:$TRANS_PERSECOND; io_s:$IOREQ_PERSECOND"
elif [ $NUM_PARM = 2 ];then
	PARM1=$1
	PARM2=$2
	case $PARM2 in
		"s")
			up_time
			UP_TIME1=$UP_TIME
			selcom
			SELECT_NUM1=$SELECT_NUM
			sleep 1
			PARM1=$[ $PARM1 - 1]
			while [ $PARM1 -gt 0 ]
			do
				selcom
				PARM1=$[ $PARM1 - 1]
				sleep 1
			done
			SELECT_NUM2=$SELECT_NUM
			up_time
			UP_TIME2=$UP_TIME
			SELECT_DIFF=$[ $SELECT_NUM2 - $SELECT_NUM1 ]
			TIME_DIFF=$[ $UP_TIME2 - $UP_TIME1 ]
			SELECT_PERSECOND=$[ $SELECT_DIFF / $TIME_DIFF]
			echo -n "sel_s:$SELECT_PERSECOND;"
		;;
		"t")
			PARM1=$1
			up_time
			UP_TIME1=$UP_TIME
			trans_num
			SUM_TRAN1=$SUM_TRAN
			sleep 1
			PARM1=$[ $PARM1 - 1]
			while [ $PARM1 -gt 0 ]
			do
				trans_num
				PARM1=$[ $PARM1 - 1]
				sleep 1
			done
			SUM_TRAN2=$SUM_TRAN
			up_time
			UP_TIME2=$UP_TIME
			TRANS_DIFF=$[ $SUM_TRAN2 - $SUM_TRAN1 ]
			TIME_DIFF=$[ $UP_TIME2 - $UP_TIME1 ]
			TRANS_PERSECOND=$[ $TRANS_DIFF / $TIME_DIFF]
			echo -n " trans_s:$TRANS_PERSECOND; "
		;;
		"i")
			PARM1=$1
			up_time
			UP_TIME1=$UP_TIME
			ionum
			SUM_IO1=$SUM_IO
			sleep 1
			PARM1=$[ $PARM1 - 1]
			while [ $PARM1 -gt 0 ]
			do
				ionum
				PARM1=$[ $PARM1 - 1]
				sleep 1
			done
			SUM_IO2=$SUM_IO
			up_time
			UP_TIME2=$UP_TIME
			IO_DIFF=$[ $SUM_IO2 - $SUM_IO1 ]
			TIME_DIFF=$[ $UP_TIME2 - $UP_TIME1 ]
			IOREQ_PERSECOND=$[ $IO_DIFF / $TIME_DIFF]
			echo -n " io_s:$IOREQ_PERSECOND"
		;;
		*)
			exit
		;;
		esac
elif [ $NUM_PARM = 3 ];then
	PARM1=$1
	PARM2=$2
	PARM3=$3
	if [ $PARM2 = "s" ] || [ $PARM2 = "t" ] && [ $PARM3 = "s" ] || [ $PARM3 = "t" ]; then
		PARM1=$1
		up_time
		UP_TIME1=$UP_TIME
		selcom
		SELECT_NUM1=$SELECT_NUM
		trans_num
		SUM_TRAN1=$SUM_TRAN
		sleep 1
		PARM1=$[ $PARM1 - 1]
		while [ $PARM1 -gt 0 ]
		do
			selcom
			trans_num
			PARM1=$[ $PARM1 - 1]
			sleep 1
		done
		SELECT_NUM2=$SELECT_NUM
		SUM_TRAN2=$SUM_TRAN
		up_time
		UP_TIME2=$UP_TIME
		SELECT_DIFF=$[ $SELECT_NUM2 - $SELECT_NUM1 ]
		TRANS_DIFF=$[ $SUM_TRAN2 - $SUM_TRAN1 ]
		TIME_DIFF=$[ $UP_TIME2 - $UP_TIME1 ]
		SELECT_PERSECOND=$[ $SELECT_DIFF / $TIME_DIFF]
		TRANS_PERSECOND=$[ $TRANS_DIFF / $TIME_DIFF]
		echo -n "sel_s:$SELECT_PERSECOND; trans_s:$TRANS_PERSECOND;"
	elif [ $PARM2 = "s" ] || [ $PARM2 = "i" ] && [ $PARM3 = "s" ] || [ $PARM3 = "i" ];
		PARM1=$1
		up_time
		UP_TIME1=$UP_TIME
		selcom
		SELECT_NUM1=$SELECT_NUM
		ionum
		SUM_IO1=$SUM_IO
		sleep 1
		PARM1=$[ $PARM1 - 1]
		while [ $PARM1 -gt 0 ]
		do
			selcom
			ionum
			PARM1=$[ $PARM1 - 1]
			sleep 1
		done
		SELECT_NUM2=$SELECT_NUM
		SUM_IO2=$SUM_IO
		up_time
		UP_TIME2=$UP_TIME
		SELECT_DIFF=$[ $SELECT_NUM2 - $SELECT_NUM1 ]
		IO_DIFF=$[ $SUM_IO2 - $SUM_IO1 ]
		TIME_DIFF=$[ $UP_TIME2 - $UP_TIME1 ]
		SELECT_PERSECOND=$[ $SELECT_DIFF / $TIME_DIFF]
		IOREQ_PERSECOND=$[ $IO_DIFF / $TIME_DIFF]
		echo -n "sel_s:$SELECT_PERSECOND; io_s:$IOREQ_PERSECOND"
	else
		PARM1=$1
		up_time
		UP_TIME1=$UP_TIME
		trans_num
		SUM_TRAN1=$SUM_TRAN
		ionum
		SUM_IO1=$SUM_IO
		sleep 1
		PARM1=$[ $PARM1 - 1]
		while [ $PARM1 -gt 0 ]
		do
			trans_num
			ionum
			PARM1=$[ $PARM1 - 1]
			sleep 1
		done
		SUM_TRAN2=$SUM_TRAN
		SUM_IO2=$SUM_IO
		up_time
		UP_TIME2=$UP_TIME
		TRANS_DIFF=$[ $SUM_TRAN2 - $SUM_TRAN1 ]
		IO_DIFF=$[ $SUM_IO2 - $SUM_IO1 ]
		TIME_DIFF=$[ $UP_TIME2 - $UP_TIME1 ]
		TRANS_PERSECOND=$[ $TRANS_DIFF / $TIME_DIFF]
		IOREQ_PERSECOND=$[ $IO_DIFF / $TIME_DIFF]
		echo -n " trans_s:$TRANS_PERSECOND; io_s:$IOREQ_PERSECOND"
	fi
	
elif [ $NUM_PARM = 4 ];then
	PARM1=$1
	PARM2=$2
	PARM3=$3
	PARM4=$4
	up_time
	UP_TIME1=$UP_TIME
	selcom
	SELECT_NUM1=$SELECT_NUM
	trans_num
	SUM_TRAN1=$SUM_TRAN
	ionum
	SUM_IO1=$SUM_IO
	sleep 1
	PARM1=$[ $PARM1 - 1]
	while [ $PARM1 -gt 0 ]
	do
		selcom
		trans_num
		ionum
		PARM1=$[ $PARM1 - 1]
		sleep 1
	done
	SELECT_NUM2=$SELECT_NUM
	SUM_TRAN2=$SUM_TRAN
	SUM_IO2=$SUM_IO
	up_time
	UP_TIME2=$UP_TIME
	SELECT_DIFF=$[ $SELECT_NUM2 - $SELECT_NUM1 ]
	TRANS_DIFF=$[ $SUM_TRAN2 - $SUM_TRAN1 ]
	IO_DIFF=$[ $SUM_IO2 - $SUM_IO1 ]
	TIME_DIFF=$[ $UP_TIME2 - $UP_TIME1 ]
	SELECT_PERSECOND=$[ $SELECT_DIFF / $TIME_DIFF]
	TRANS_PERSECOND=$[ $TRANS_DIFF / $TIME_DIFF]
	IOREQ_PERSECOND=$[ $IO_DIFF / $TIME_DIFF]
	echo -n "sel_s:$SELECT_PERSECOND; trans_s:$TRANS_PERSECOND; io_s:$IOREQ_PERSECOND"
else
	echo "You have not input any parameter!"
	exit
fi

