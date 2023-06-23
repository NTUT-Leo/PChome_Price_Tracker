virtualenv -p python3.6 ./python3_virtual_env
source ./python3_virtual_env/bin/activate

cd PChome_Price_Tracker

pip install -r requirements.txt

runTest(){
    date
    robot -F robot -d ./out/$BUILD_NUMBER --output output.xml -l log.html -r report.html -P ./"keywords" -L TRACE:INFO PChome\ Price\ Tracker.robot
}

runTest

deactivate
