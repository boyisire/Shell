#*******************************************************************************
#* Subject  *: 分割文本文件
#* Editor   *: Hu
#* CreDate  *: 2013-11-07 14:57:54 
#* AltDate  *: 2013-11-15 09:55:57
#* Describe *: 
#		1.根据需求配置好带★ 参数.
#		2.该文中由于命令du和ls所使用的换算进制不同,所以文件大小只能是估算值,不精确.
#		3.分割后文件大小可能不一定相等,这属于正常现象.
#		4.本文分割用split命令,它分割后默认是以字母结尾,需要手动处理为数字结尾.
#		5.为了保险起见,分割完后,未删除源文件;如有相关需求,打开带☆ 注释即可.
#*******************************************************************************
#BegExecTime=`date +%s`
#clear



#**********************************初始化参数**********************************#
#★ 文件列表修饰符(起过滤文件的作用)
FilePreFix=""

#★ 要分割多大的文件(单位：Mb)
FixFileSize=8000

#★ 要将文件分割为多大(单位：Mb)
SubFileSize=1000

#★ 基准行数(为了方便计算每行的大小,数字越大越精确,但同时效率也就相应变慢)
BaseRow=10000

#临时文件
TmpFile=tmp_$$

#待分割文件列表(默认情况下此项不变,除非想把换算进制由1000变为1024)
FileList=`ls -l $FilePreFix 2>>/dev/null|awk '{if($5/1000/1000>='$FixFileSize'){print $9}}'`



#**********************************自定义函数**********************************#
#加载公共函数库
. ${GTSHOME}/bin/ShellScript.lib

Fun_ReplaceName()
#***************************************************
#** 功能:把子文件按数字结尾方式改名(默认为字母)  
#**                                        
#** 格式:Fun_ReplaceName  "子文件前缀" "子文件后缀" "分割方式"            
#***************************************************
{
Sub_FileList=`ls $1`	#子文件列表
tmp_num=1

for sub_file in $Sub_FileList
do		
	tmp_Prefix=`echo $sub_file|sed 's/__.*$//g'`
	#子文件格式=文件前缀_数字标识.文件后缀
	subFileName=`printf "%s_%02s%s\n" $tmp_Prefix $tmp_num $2`
	echo $subFileName
	mv $sub_file $subFileName 2>>/dev/null
	
	if [ "$3" != "1" ]
	then
		if [ $tmp_num -eq 1 ]
		then
			Last_File=$subFileName
			Curr_File=$subFileName			
		else			
			Last_File=$Curr_File
			Curr_File=$subFileName
			#把当前文件第1行追加到上个文件
			head -n 1 $Curr_File >>$Last_File
			#去掉当前文件的第一行
			sed '1d' $Curr_File >${Curr_File}.tmp
			mv ${Curr_File}.tmp ${Curr_File}
			
		fi
	fi
	tmp_num=`expr $tmp_num + 1`		
done
}


#***********************************主 程 序***********************************#
#根据列表取文件
if [ "$FileList" != "" ]
then
	printf "[%s] 要分割的文件有：\n%-s\n\n" "`Fun_Now`" "$FileList"
	printf "请选择分割方式(1-按行;0|回车-按大小[默认]):"
	read SpFlag
			 	
			
	for FileName in `ls $FileList`
	do
		
		#取得源文件大小
		FileSize=`du -m $FileName|awk '{print $1}'`
		#取得源文件行数
		FileRow=`sed -n '$=' $FileName`
		#取得源文件前缀以作为子文件前缀用
		FileNamePrefix=`echo $FileName|sed 's/\..*$//g'`
		#取得源文件后缀以作为子文件后缀用
		FileNameSuffix=`echo $FileName|cut -d '.' -f 2`
		
		#预算出每个子文件大概的行数,需建立临时文件做中转.
		#算法解析：每个子文件预估行数≈=(预设子文件大小值*1000[把其由M转为K] / 每行的大小[临时文件总大小/临时文件总行数])
		sed -n "1,$BaseRow w $TmpFile" $FileName
		tmpFileSize=`du -k $TmpFile|awk '{print $1}'`
		EachFileRow=`echo "scale=3;a=$tmpFileSize/$BaseRow;b=$SubFileSize*1000;scale=0;b/a"|bc`
		#echo $EachFileRow
		rm -f $TmpFile
							
		#子文件前缀	
		SubFilePrefix=$FileNamePrefix"__"
		#子文件后缀
		SubFileSuffix="."$FileNameSuffix	
		
		#分割文件
		if [ "$SpFlag" == "1" ]
		then
			echo "***按文件行数分割***"
		 	Fun_Split "$EachFileRow" "$FileName" "$SubFilePrefix" "$SpFlag"
		 	if [ $? -ne 0 ];then echo "Error!!! Please Connect Function Lib.";exit -127;fi
		else	
			echo "***按文件大小分割***"		
			Fun_Split "$SubFileSize" "$FileName" "$SubFilePrefix" "$SpFlag"
			if [ $? -ne 0 ];then echo "Error!!! Please Connect Function Lib.";exit -127;fi
		fi		
			
		echo "[`Fun_Now`] 文件【$FileName】分割后的子文件为:"
		#由于默认分割后的文件是以字母结尾，需重命名为以数字结尾.
		Fun_ReplaceName "$SubFilePrefix*" "$SubFileSuffix" "$SpFlag"
		echo ""	
		
		#☆ rm -f $FileName
	done	
else
	echo "没有找到大于[$FixFileSize M]的文件，请查证后重试!"
	exit -1
fi

EndExecTime=`date +%s`
echo "------------------------------------------------------------------"
echo "[`Fun_Now`] 程序<$0>"`Fun_ExecTime "$BegExecTime" "$EndExecTime"`
exit 0