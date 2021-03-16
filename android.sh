#! /bin/bash

string=$1
file=$2
len=${#string}
OLD_IFS="$IFS"
IFS=","
array=($string)
IFS="$OLD_IFS"
for var in ${array[@]}
do
	OLD_IFS="$IFS"
	IFS=":"
	arr=($var)
	IFS="OLD_IFS"
	#Maven
	url=https://repo1.maven.org/maven2/
	#JCenter
	url2=https://jcenter.bintray.com/
	#判断依赖库的真实性
	string1=${arr[0]}
	string2=${string1//./'/'}
	if [ "${arr[1]}" =  "" ];then
		echo "参数错误1"
		exit
	fi
	if [ "${arr[2]}" =  "" ];then
		echo "参数错误2"
		exit
	fi
	string3=$string2/${arr[1]}/${arr[2]}
	result=`curl -s $url$string3`
	code=404
	if [[ $result =~ $code ]];then
		result=`curl -s $url2$string3`
		echo $result
		if([[ $result =~ $code ]]);then
			echo "bad path"
			exit
		else
			echo "find path"
		fi
	else 
		echo "find path"
	fi
	#添加依cd
	path=${arr[0]}:${arr[1]}
	if grep $path $file;then
	      imp=`grep $path $file`
	      sed -i "s/$imp/    implementation '$var'/" $file
	      echo "update $var dependencies"
        else
	      sed -i '$i\    implementation '"'$var'"'' $file
	      echo "add new dependencies"
 	fi		
done


