virtualenv -p python3.6 ./python3_virtual_env
source ./python3_virtual_env/bin/activate

cd PChome_Price_Tracker

pip install -r requirements.txt

runTest(){
    ROUND=0
    robot -F robot -d ./out/$BUILD_NUMBER -o output-0.xml -l NONE -r NONE -P ./"keywords" -L TRACE:INFO PChome\ Price\ Tracker.robot
    while [[ $? -ne 0 && $ROUND -lt $FAIL_RETRY ]]; do
        date
        ((ROUND++))
        robot -F robot -d ./out/$BUILD_NUMBER -o output-$ROUND.xml -l NONE -r NONE -P ./"keywords" -L TRACE:INFO PChome\ Price\ Tracker.robot
    done
    date
}

postProcessing(){
    echo =================================Test==Result=================================
    rebot -d ./out/$BUILD_NUMBER/result -o output.xml -l log.html -r report.html --merge ./out/$BUILD_NUMBER/output-*.xml
    echo ================================Merged==Output================================
    rebot -d ./out/$BUILD_NUMBER -l log.html -r report.html --name PChome\ Price\ Tracker ./out/$BUILD_NUMBER/output-*.xml
    rm -f ./out/$BUILD_NUMBER/output-*.xml
}

runTest
postProcessing

deactivate