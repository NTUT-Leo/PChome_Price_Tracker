cd PChome_Price_Tracker

pip install -r requirements.txt

TIME /T
robot -F robot -d ./out/%BUILD_NUMBER% --output output.xml -l log.html -r report.html -P ./ -P ./"keywords" -L TRACE:INFO "PChome Price Tracker.robot"