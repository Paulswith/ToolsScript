## 使用指南:
## 0.xcoodebuild美化工具安装, `gem install xcpretty`
## 1.在项目根目录,新建文件夹`package`, 放脚本和`ExportOptions.plist`文件
## 2.脚本新增执行权限 `chmod +x ./package/package.sh`
## 3.配置下方user-define的信息
## 
# *******************************************************************************
# ----------------user-define----------------------------------------------------
# 这三项可以在项目根目录 `xcodebuild -list`查询到:
export workspace= #*.xcworkspace
export scheme=
export configuration=release # debug/release/
# 配置存储旧包目录, 为了安全起见, 还是存起来吧
export packageSaveDir=/tmp/packageSaveDir  # 最后不要加斜杠
# -------------------------------------------------------------------------------
# *******************************************************************************

# ----------------default-define-----------------------
export archivePath=./package/build/$scheme.xcarchive
export exportPath=./package/build # 最后不要加斜杠
export exportOptionPlist=./package/ExportOptions.plist
# -----------------------------------------------------

# ------------------log-define-------------------------
# 0.0 打印日志
logName=`date "+%Y-%m-%d_%H-%M-%S"`
export packageLog="./package/${logName}.log"
function logger
{
	local msg=$1
	local DATE=`date +"%F %X"`
	echo "[${DATE}] | ${msg}" | tee -a ${packageLog}
}
# 标志新日志输出
logger "\n*************\n\n>PACKAGE SPLIT AND START:<\n\n*************"
# -----------------------------------------------------


logger  "\033[34m Step 1.[*****************Dependencies checking...*****************] \033[0m"
if [[ `ls $exportOptionPlist` ]]; then
	logger "\t\033[32m [Log~info]: exportOptionPlist确认配置存在 \033[0m"
else
	logger "\t\033[31m [Log~info]: exportOptionPlist不存在,无法继续进行 \033[0m"
	exit 1
fi


logger  "\033[34m Step 2.[*****************Clean build cache...*****************] \033[0m"
# 2.1 清除构建缓存
xcodebuild clean -workspace $workspace -scheme $scheme -configuration $configuration | xcpretty | tee -a ${packageLog}


logger  "\033[34m Step 3.[*****************Backup old package...*****************] \033[0m"
# 3.1 检查保存目录是否存在,else创建
if [[ `ls $packageSaveDir` ]]; then
	logger "\t\033[32m [Log~info]: ${packageSaveDir}目录已存在 \033[0m"
else
	logger "\t\033[35m [Log~info]: ${packageSaveDir}目录不存在,执行创建 \033[0m"
	mkdir -p $packageSaveDir | tee -a ${packageLog}
fi

# 3.3 导出目录是否存在, else创建
if [[ `ls $exportPath` ]]; then
	logger "\t\033[32m [Log~info]: ${exportPath}目录已存在 \033[0m"
	hasOldPackage=`ls -l $exportPath | grep "$scheme" | wc -l`
	# 3.4 导出目录如果存在,里面有类似package名字的包, 就备份到存储目录, 并清空该目录
	if [[ $hasOldPackage -gt 0 ]]; then
		logger "\t\033[32m [Log~info]: 存在[${hasOldPackage}]个旧包相关文件, 开始执行备份: \033[0m"
		packageFullPath=`date +${packageSaveDir}/${scheme}_%Y-%m-%d_%H:%M:%S.gz`
		# 3.5 打包备份
		tar zcf ${packageFullPath} ${exportPath} | tee -a ${packageLog}
		if [[ $? -eq 0 ]]; then
			logger "\t\033[32m [Log~info]: 备份完成,存储 ${exportPath} ->-> ${packageFullPath}  \033[0m"
			# 3.6移除旧包
			rm -rf $exportPath/* | tee -a ${packageLog} # 删除旧包路径下的文件
		else
			logger "\t\033[35m [Log~info]: 备份失败,请检查! \033[0m"
		fi	
	fi
else
	logger "\t\033[35m [Log~info]: ${exportPath}目录不存在,执行创建 \033[0m"
	mkdir -p $exportPath | tee -a ${packageLog}
fi


logger "\033[34m Step 4.[*****************start build project*****************] \033[0m"
# 4.1执行构建
# 不需要指定:CODE_SIGN_IDENTITY="$code_sign_indentity" 
xcodebuild archive -workspace $workspace -scheme $scheme -configuration \
$configuration -archivePath $archivePath -destination generic/platform=ios | xcpretty | tee -a ${packageLog}

# 4.2 若发现执行码非0,表示失败了,
if [[ $? -eq 0 ]]; then
	logger  "\t\033[32m [Log~info]: build succeed! \033[0m"
else
	logger  "\t\033[31m [Log~info]: build fail! please check! \033[0m"
	exit 1
fi


logger  "\033[34m Step 5.[*****************Export  package to .IPA*****************] \033[0m"
# 5.1 执行打包
xcodebuild -exportArchive -archivePath $archivePath \
-exportPath $exportPath -destination generic/platform=ios \
-exportOptionsPlist $exportOptionPlist -allowProvisioningUpdates | xcpretty | tee -a ${packageLog}
# 5.2若是打包失败了, 就停止并抛出
if [[ $? -eq 0 ]]; then
	logger  "\t\033[32m [Log~info]: Export Succeeded! \033[0m"
else
	logger  "\t\033[31m [Log~info]: Export fail! please check! \033[0m"
	exit 1
fi
