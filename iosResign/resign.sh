#/bin/bash


#----------------- please add you codesign inf ---------------------------------------------------
# signStr="iPhone Developer: Example (ABCEDFGHC)"
signStr=""
if [[ $# < 2 ]]; then
  echo "input the argv format like -> ./current.sh destintion-App.ipa valid.provision"
  exit
fi
if test $signStr = "";then
	echo "please add you codesign info,or command: security find-identity -v -p codesigning found it"
fi
provision=$2  
tempPlace=/tmp/project_resign
#------------------------config--------------------------------------------------------------------


echo "Log info : remove temp file $tempPlace and unzip IPA"
rm -rf /tmp/project_resign
unzip -oq $1 -d $tempPlace
whichApp=`ls $tempPlace/Payload`
appPlace="$tempPlace/Payload/$whichApp"
echo "Log info : destintion-App => $appPlace"


echo "Log info : generation Entitlements.plist and copy to app inside:"
security cms -D -i $provision > ProvisionProfile.plist 
/usr/libexec/PlistBuddy -x -c "Print Entitlements" ProvisionProfile.plist > $tempPlace/Entitlements.plist
cp $provision $appPlace/embedded.mobileprovision


echo "Log info : remove Extension and Watch and PlugIns"
#获取info.plist的bundleID  // 如果指定了$3修改bundle就修改下
plutil -remove CFBundleREsourceSpecification $appPlace/Info.plist   #删除签名源文件相关
# plutil -remove NSUserActivityTypes $appPlace/Info.plist 			#删除Extension相关,发现不删这个也没问题就没删了
rm -rf $appPlace/Watch  #发现watch插件必现失败,这个必须删除了
rm -rf $appPlace/PlugIns #发现PlugIns插件必现失败,这个必须删除了,就算下面重签也不管的, 坑超多


BundleID=`plutil -p $appPlace/Info.plist | grep 'CFBundleIdentifier'`
echo "Log info : current BundleID: ${BundleID}"
if [[ $3 ]]; then
	plutil -replace CFBundleIdentifier -string "$3" $appPlace/Info.plist
	reBundleID=`plutil -p $appPlace/Info.plist | grep 'CFBundleIdentifier' `
	echo "Log info : you wanna replace to: ${reBundleID}"
fi


echo "Log info :  remove original sign file ... ... "
codesignInfo=`find $appPlace -name "CodeResources" `
for i in $codesignInfo; do
	# echo $i
	rm -f $i
done



echo "Log info :  resign more relate ,like framework,dylib  so on... ... "
allShouldSign=` find $appPlace -name "*.appex" && find $appPlace  -name "*.framework" && find $appPlace  -name "*.dylib" && find $appPlace/* -name "*.app" ` #最上层的先不签
for i in $allShouldSign; do
	codesign -fs "${signStr}" --no-strict --entitlements=/tmp/project_resign/Entitlements.plist $i
done


echo "\n------------------------Log info : start resign:-----------------"
codesign -vvv -fs "$signStr" --no-strict --entitlements=/tmp/project_resign/Entitlements.plist $appPlace
echo "-----------------------------------------------------------------\n"


#显示签名后的信息
echo "\n------------------------Log info : after resign:-----------------"
codesign -d -vvv --file-list - $appPlace
echo "-----------------------------------------------------------------\n"


echo "Log info : packaging ... ..."
cd $tempPlace
zip -qry sign.ipa ./Payload
mv $tempPlace/sign.ipa ~/Desktop

echo "Log info : remove temp file"
rm -rf $tempPlace

echo "Log info : succeed ! Please open the Desktop to view"

