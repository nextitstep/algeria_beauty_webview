@echo off
setlocal enabledelayedexpansion

set SERVER_KEY=AIzaSyD90rU5ecYSXirDL4cLbYBQx_L8xaNZ7ww
set DEVICE_TOKEN=DEVICE-FCM-TOKEN

for /L %%i in (1,1,10) do (
    echo Sending notification %%i of 10
    curl -X POST ^
    -H "Authorization: key=%SERVER_KEY%" ^
    -H "Content-Type: application/json" ^
    -d "{ \"to\": \"%DEVICE_TOKEN%\", \"notification\": { \"title\": \"Test Notification %%i\", \"body\": \"This is test notification number %%i\" }, \"data\": { \"payload\": \"custom_data\" } }" ^
    https://fcm.googleapis.com/fcm/send
    
    timeout /t 2 /nobreak >nul
)

echo All notifications sent!
pause