#!/bin/bash
while :;
do
line=`curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "get_stext", "id":123, "params": [] }' video.p6way.net | sed "s/^..jsonrpc.........result...//" | sed "s/...id.:123.$//"`
text=`echo "$line" | sed "s/---\[\[slnc ....\]\]\|//g" | sed "s/\|\|/|/g" | sed "s/---//g"| sed "s/ /^/g" | sed "s/|/. /g"`

#lf=$'\n'; echo "$line" | sed "s/\|/\\$lf/g" | sed "s/ /^/g" | sed  "s/^---.*//g" | grep  -v "^$"> timing.txt

for words in $text
do
  say -v milena -r 190 -o timing.wav --data-format=LEF32@22050 [[slnc 500]] $words [[slnc 500]]
  sec=`mediainfo --Inform="Audio;%Duration%" timing.wav`
  secbc=`echo "1000/$sec" | bc -l`
  #echo $secbc $words
done

LENGTH=`echo $text | wc -c`
if [ "$LENGTH" -gt "1"  ]
then

voice=`curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "get_voice", "id":123, "params": [] }' video.p6way.net | sed "s/^..jsonrpc.........result...//" | sed "s/...id.:123.$//"`
echo inside "$text" end
say -v $voice "$text" -r 190 -o hi.wav --data-format=LEF32@22050
#Samantha Milena
echo -n '{"jsonrpc": "2.0", "method": "get_data_mp3", "id":1, "params": ["' > data.json
base64 -i hi.wav > hi.b64
cat hi.b64  | tr -d '\n'>> data.json
echo -n '"] }' >> data.json

HIB64=`cat hi.b64`
curl -X POST -H "Content-Type: application/json" -d @data.json video.p6way.net


fi
sleep 1;

done
