#!/usr/bin/env bash

#---------------------------------------------------------------
# description: SensorsData Flutter AutoTrack Script
# author: zhangwei@sensorsdata.cn
# copyright: SensorsData All Reserved.
#---------------------------------------------------------------

##### settings
set -u  #设置变量不存在时报错
#set -x  #用于分隔命令执行时输出对应的命令
#set -e  #当脚本发生错误时，终止执行

##### welcome message
echo -e "\033[32m
                  Welcome to use SensorsData Flutter Autotrack Script. 
If you have any question, please contact our service technicist or our QQ group or WeChat Group.
              Script Version: V1.0.1, Support Flutter Versions: 2.0.6、2.2.2、2.2.3

\033[0m"

##### handle options
## -r reset futter
## -n nullsafety support
## getopts short option, getopt long option. Mac os do not support getopt command!
## reference: https://blog.csdn.net/ARPOSPF/article/details/103381621
while getopts ":r" opt; do
  case $opt in
    r)
        echo -e "\033[47;34m INFO: start to reset flutter, please wait \033[0m"
        TMP_FLUTTER_ROOT=$(type -p flutter)
        if [ $? -ne 0 ] ;then
            echo -e "\033[31m  Error: Can not found flutter command, please make sure your flutter is installed correctly! \033[0m"
            exit 1
        fi
        TMP_FLUTTER_ROOT=${TMP_FLUTTER_ROOT#flutter is }
        TMP_FLUTTER_ROOT=${TMP_FLUTTER_ROOT%bin/flutter}
        echo $TMP_FLUTTER_ROOT
        cd $TMP_FLUTTER_ROOT
        comit_id=$(git rev-parse HEAD)
        git reset --hard $comit_id
        rm -rf bin/cache
        flutter --version
        echo -e "\033[32m Reset Flutter Finished \033[0m"
        exit 0
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
  esac
done

shift $(($OPTIND - 1))

# echo remaining parameters=[$@]
# echo \$1=[$1]
# echo \$2=[$2]
# exit 1


##### define directory names
ASPECTD_DIR="sa_flutter_aspectd"
ASPECTD_FRONTEND="sa_aspectd_frontend"
ASPECTD_IMPL="sa_aspectd_impl"
readonly ASPECTD_DART_SDK_DIR
readonly ASPECTD_DIR
readonly aspectd_impl

CURRENT_PATH=$(pwd)

## check git command exist
type git
if [ $? -ne 0 ] ; then
echo -e "\033[31m  Error: Can not found git command, we use it to manage project, please read README file. \033[0m"
exit 1
fi

##### check flutter root and check if a git project
FLUTTER_ROOT=$(type -p flutter)
if [ $? -ne 0 ] ;then
echo -e "\033[31m  Error: Can not found flutter command, please make sure your flutter is installed correctly! \033[0m"
exit 1
fi
FLUTTER_ROOT=${FLUTTER_ROOT#flutter is }
FLUTTER_ROOT=${FLUTTER_ROOT%/bin/flutter}
echo "Flutter Path is $FLUTTER_ROOT"

## check flutter version
echo -e "\033[47;34m INFO: Check flutter version \033[0m"
FLUTTER_VERSION=$(flutter --version | grep -Eo "Flutter [0-9]+\.[0-9]+\.[0-9]+")
FLUTTER_VERSION=${FLUTTER_VERSION#Flutter }
echo "Flutter Version is $FLUTTER_VERSION"

## 检查 Flutter SDK 是否有更改，提醒其重置
cd "$FLUTTER_ROOT"
git status
if [ -n "$(git status --porcelain)" ]; then 
    echo "  "
    echo "  "
    echo -e "\033[5;41;33m Your flutter sdk is modified, do you want to reset it first? \033[0m" 
    read -p  "Enter [y/n]" input
    case $input in
            [yY]*)
                    echo "start to reset your flutter sdk."
                    comit_id=$(git rev-parse HEAD)
                    git reset --hard $comit_id
                    rm -rf bin/cache
                    flutter --version
                    ;;
            [nN]*)
                    echo "You can reset your flutter sdk manually, then run this shell script again. Now exit."
                    exit 1
                    ;;
            *)
                    echo "Just enter y or n, please."
                    exit
                    ;;
    esac
fi
cd -
pwd

echo -e "\033[47;34m INFO: Start clone dependecies \033[0m"
# 删除以下目录
rm -rf $ASPECTD_DIR  $ASPECTD_FRONTEND  $ASPECTD_IMPL

# 重新下载
# gitlab internal
# git clone http://gitlab.internal.sensorsdata.cn/sensors-analytics/sdk/sa_aspectd_frontend.git
# git clone http://gitlab.internal.sensorsdata.cn/sensors-analytics/sdk/sa_flutter_aspectd.git
# git clone http://gitlab.internal.sensorsdata.cn/sensors-analytics/sdk/sa_aspectd_impl.git

#github 
git clone https://FlutterCustomerOfSensorsData:534623251964b1c4d620fc771b96f02dc146eec2@github.com/sensorsdata/sa_aspectd_frontend.git
git clone https://FlutterCustomerOfSensorsData:534623251964b1c4d620fc771b96f02dc146eec2@github.com/sensorsdata/sa_flutter_aspectd.git
git clone https://FlutterCustomerOfSensorsData:534623251964b1c4d620fc771b96f02dc146eec2@github.com/sensorsdata/sa_aspectd_impl.git


##### 将 aspectd frontend 切换到指定的版本上
echo "${CURRENT_PATH}/${ASPECTD_FRONTEND}"
pushd "${CURRENT_PATH}/${ASPECTD_FRONTEND}"   ##切换到 aspectd 目录
if [[ $FLUTTER_VERSION = "2.2.3" ]]; then
    git checkout "v2.2.3"
elif [[ $FLUTTER_VERSION = "2.2.2" ]]; then
    git checkout "v2.2.2"
elif [[ $FLUTTER_VERSION = "2.0.6" ]]; then
    git checkout "v2.0.6"
else 
    echo -e "\033[31m  Error: Your flutter version is '$FLUTTER_VERSION', maybe not support this version, please check our support versions. \033[0m"
    exit 1
fi
popd

##### rename flutter sdk frontend server
pwd
echo -e "\033[47;34m INFO:rename flutter sdk frontend server. \033[0m"

pushd "$FLUTTER_ROOT/bin/cache/artifacts/engine/darwin-x64"
# 判断文件是否存在，不存在的情况下才需要复制
if [ ! -e "frontend_server.dart.snapshot$FLUTTER_VERSION" ]; then
  mv "frontend_server.dart.snapshot" "frontend_server.dart.snapshot$FLUTTER_VERSION"
fi
popd 
echo "current path is: "
pwd 

##### copy frontend
echo -e "\033[47;34m INFO:copy frontend server. \033[0m"
os=$(uname -a)
OS_PLATFORM_DIR_NAME="darwin-x64" 
if [[ $os =~ 'Msys' ]] || [[ $os =~ 'msys' ]]; then
    echo "windows platform"
    OS_PLATFORM_DIR_NAME="windows-x64"
elif [[ $os =~ 'Darwin' ]]; then 
    echo "mac platform"
    OS_PLATFORM_DIR_NAME="darwin-x64"
else
    OS_PLATFORM_DIR_NAME="linux-x64"
    echo "other linux platform"
fi
cp "$ASPECTD_FRONTEND/lib/flutter_frontend_server/frontend_server.dart.snapshot"  "$FLUTTER_ROOT/bin/cache/artifacts/engine/$OS_PLATFORM_DIR_NAME/frontend_server.dart.snapshot"

echo "current path is: "
pwd 

##### run pub get
echo -e "\033[47;34m INFO:start run pub get. \033[0m"
echo "aspectd pub get"
pushd $ASPECTD_DIR
flutter pub get
popd

echo "aspectd_impl pub get"
pushd $ASPECTD_IMPL
flutter pub get
popd

echo -e "\033[32m Finish \033[0m"