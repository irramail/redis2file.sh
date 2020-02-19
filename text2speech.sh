#!/bin/bash
while :;
do
text=`curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method": "get_stext", "id":123, "params": [] }' 192.168.0.99 | sed "s/^..jsonrpc.........result...//" | sed "s/...id.:123.$//" | sed "s/|/. /g"`

LENGTH=`echo $text | wc -c`
if [ "$LENGTH" -gt "1"  ]
then
echo inside "$text" end
say -v Milena "$text" -r 190 -o hi.wav --data-format=LEF32@22050

echo -n '{"jsonrpc": "2.0", "method": "get_data_mp3", "id":1, "params": ["' > data.json
base64 -i hi.wav > hi.b64
cat hi.b64  | tr -d '\n'>> data.json
echo -n '"] }' >> data.json

HIB64=`cat hi.b64`
curl -X POST -H "Content-Type: application/json" -d @data.json 192.168.0.99


fi
sleep 1;

done
