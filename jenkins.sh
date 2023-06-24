virtualenv -p python3.6 ./python3_virtual_env
source ./python3_virtual_env/bin/activate

cd PChome_Price_Tracker

pip install -r requirements.txt

runTest(){
    date
    robot -F robot -d ./out/$BUILD_NUMBER -o output-1.xml -l NONE -r NONE -P ./"keywords" -L TRACE:INFO PChome\ Price\ Tracker.robot
    ROUND=2
    while [ $? -ne 0 ] && [ $ROUND -le $FAIL_RETRY ]; do
        robot -F robot -d ./out/$BUILD_NUMBER -o output-$ROUND.xml -l NONE -r NONE -P ./"keywords" -L TRACE:INFO PChome\ Price\ Tracker.robot
        ((ROUND++))
    done
    rebot -d ./out/$BUILD_NUMBER -l log.html -r report.html --merge --name output ./out/$BUILD_NUMBER/output-*.xml
}

runTest

deactivate
