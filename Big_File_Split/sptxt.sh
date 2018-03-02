#*******************************************************************************
#* Subject  *: �ָ��ı��ļ�
#* Editor   *: Hu
#* CreDate  *: 2013-11-07 14:57:54 
#* AltDate  *: 2013-11-15 09:55:57
#* Describe *: 
#		1.�����������úô��� ����.
#		2.��������������du��ls��ʹ�õĻ�����Ʋ�ͬ,�����ļ���Сֻ���ǹ���ֵ,����ȷ.
#		3.�ָ���ļ���С���ܲ�һ�����,��������������.
#		4.���ķָ���split����,���ָ��Ĭ��������ĸ��β,��Ҫ�ֶ�����Ϊ���ֽ�β.
#		5.Ϊ�˱������,�ָ����,δɾ��Դ�ļ�;�����������,�򿪴��� ע�ͼ���.
#*******************************************************************************
#BegExecTime=`date +%s`
#clear



#**********************************��ʼ������**********************************#
#�� �ļ��б����η�(������ļ�������)
FilePreFix=""

#�� Ҫ�ָ�����ļ�(��λ��Mb)
FixFileSize=8000

#�� Ҫ���ļ��ָ�Ϊ���(��λ��Mb)
SubFileSize=1000

#�� ��׼����(Ϊ�˷������ÿ�еĴ�С,����Խ��Խ��ȷ,��ͬʱЧ��Ҳ����Ӧ����)
BaseRow=10000

#��ʱ�ļ�
TmpFile=tmp_$$

#���ָ��ļ��б�(Ĭ������´����,������ѻ��������1000��Ϊ1024)
FileList=`ls -l $FilePreFix 2>>/dev/null|awk '{if($5/1000/1000>='$FixFileSize'){print $9}}'`



#**********************************�Զ��庯��**********************************#
#���ع���������
. ${GTSHOME}/bin/ShellScript.lib

Fun_ReplaceName()
#***************************************************
#** ����:�����ļ������ֽ�β��ʽ����(Ĭ��Ϊ��ĸ)  
#**                                        
#** ��ʽ:Fun_ReplaceName  "���ļ�ǰ׺" "���ļ���׺" "�ָʽ"            
#***************************************************
{
Sub_FileList=`ls $1`	#���ļ��б�
tmp_num=1

for sub_file in $Sub_FileList
do		
	tmp_Prefix=`echo $sub_file|sed 's/__.*$//g'`
	#���ļ���ʽ=�ļ�ǰ׺_���ֱ�ʶ.�ļ���׺
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
			#�ѵ�ǰ�ļ���1��׷�ӵ��ϸ��ļ�
			head -n 1 $Curr_File >>$Last_File
			#ȥ����ǰ�ļ��ĵ�һ��
			sed '1d' $Curr_File >${Curr_File}.tmp
			mv ${Curr_File}.tmp ${Curr_File}
			
		fi
	fi
	tmp_num=`expr $tmp_num + 1`		
done
}


#***********************************�� �� ��***********************************#
#�����б�ȡ�ļ�
if [ "$FileList" != "" ]
then
	printf "[%s] Ҫ�ָ���ļ��У�\n%-s\n\n" "`Fun_Now`" "$FileList"
	printf "��ѡ��ָʽ(1-����;0|�س�-����С[Ĭ��]):"
	read SpFlag
			 	
			
	for FileName in `ls $FileList`
	do
		
		#ȡ��Դ�ļ���С
		FileSize=`du -m $FileName|awk '{print $1}'`
		#ȡ��Դ�ļ�����
		FileRow=`sed -n '$=' $FileName`
		#ȡ��Դ�ļ�ǰ׺����Ϊ���ļ�ǰ׺��
		FileNamePrefix=`echo $FileName|sed 's/\..*$//g'`
		#ȡ��Դ�ļ���׺����Ϊ���ļ���׺��
		FileNameSuffix=`echo $FileName|cut -d '.' -f 2`
		
		#Ԥ���ÿ�����ļ���ŵ�����,�轨����ʱ�ļ�����ת.
		#�㷨������ÿ�����ļ�Ԥ��������=(Ԥ�����ļ���Сֵ*1000[������MתΪK] / ÿ�еĴ�С[��ʱ�ļ��ܴ�С/��ʱ�ļ�������])
		sed -n "1,$BaseRow w $TmpFile" $FileName
		tmpFileSize=`du -k $TmpFile|awk '{print $1}'`
		EachFileRow=`echo "scale=3;a=$tmpFileSize/$BaseRow;b=$SubFileSize*1000;scale=0;b/a"|bc`
		#echo $EachFileRow
		rm -f $TmpFile
							
		#���ļ�ǰ׺	
		SubFilePrefix=$FileNamePrefix"__"
		#���ļ���׺
		SubFileSuffix="."$FileNameSuffix	
		
		#�ָ��ļ�
		if [ "$SpFlag" == "1" ]
		then
			echo "***���ļ������ָ�***"
		 	Fun_Split "$EachFileRow" "$FileName" "$SubFilePrefix" "$SpFlag"
		 	if [ $? -ne 0 ];then echo "Error!!! Please Connect Function Lib.";exit -127;fi
		else	
			echo "***���ļ���С�ָ�***"		
			Fun_Split "$SubFileSize" "$FileName" "$SubFilePrefix" "$SpFlag"
			if [ $? -ne 0 ];then echo "Error!!! Please Connect Function Lib.";exit -127;fi
		fi		
			
		echo "[`Fun_Now`] �ļ���$FileName���ָ������ļ�Ϊ:"
		#����Ĭ�Ϸָ����ļ�������ĸ��β����������Ϊ�����ֽ�β.
		Fun_ReplaceName "$SubFilePrefix*" "$SubFileSuffix" "$SpFlag"
		echo ""	
		
		#�� rm -f $FileName
	done	
else
	echo "û���ҵ�����[$FixFileSize M]���ļ������֤������!"
	exit -1
fi

EndExecTime=`date +%s`
echo "------------------------------------------------------------------"
echo "[`Fun_Now`] ����<$0>"`Fun_ExecTime "$BegExecTime" "$EndExecTime"`
exit 0