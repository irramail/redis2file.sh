#!/bin/bash
while :;
do

keytimes=$(redis-cli --scan | grep "^times$")
if  [[ "$keytimes" == "times" ]]
then
  rm -f ./zooming/TIME_TEXT_*

  times=`redis-cli get times | sed  "s/|/ /g"`
  CNTTEXT=0
  for time in $times
  do
    let CNTTEXT=$CNTTEXT+1
    echo $time > ./zooming/TIME_TEXT_"$CNTTEXT"
  done

  redis-cli del times
fi

keym4a=$(redis-cli keys "m4a")
for key in $keym4a
do
if  [[ "$key" == "m4a" ]]
then
  redis-cli get m4a | sed "s/|/\n/g" | sed "s/^.*,//" >  ./linesM4a.b64
  for  i in `cat ./linesM4a.b64`
  do
    echo $i | base64 -d > ./m4a/hi.wav
  done
  redis-cli del m4a
  redis-cli set stext ""
fi
done

keytext=$(redis-cli keys "text")
for key in $keytext
do
if  [[ "$key" == "text" ]]
then
  COUNTER=0
  BTEXT=`redis-cli get text`
  rm -f TEXT_*
  redis-cli get text | sed "s/|/\n/g" | sed "s/ /_/g" >  lines.txt
  sed -i "s/^---.*$//g" lines.txt
  sed -i "s/\[\[.*\]\]//" lines.txt
  sed -i "/^$/d" lines.txt
  for  i in `cat lines.txt`; do let COUNTER=$COUNTER+1; echo $i | sed "s/_/ /g" > TEXT_"$COUNTER"; done
  redis-cli set btext "$BTEXT"
  redis-cli del text
fi
done

keybgcount=$(redis-cli keys "bgcounter")
for key in $keybgcount
do
if [[ "$key" == "bgcounter" ]]
then
color=`redis-cli get color`
rm -f canvas.jpg
convert -background "#$color"ff -fill white -gravity center -geometry +0+0 -size 1920x1080  caption:" " ~/blank/blank1920x1080.jpg +swap -gravity south -composite ~/canvas.jpg

redis-cli set svg ""

count=`redis-cli get bgcounter`
for i in `seq 1 $count`
do
redis-cli append svg `base64 canvas.jpg | tr -d '\n'`
if [ "$i" -ne "$count" ]
then
redis-cli append svg "|"
fi
done

redis-cli del bgcounter
fi
done

keyimg=$(redis-cli --scan | grep "^img$")
if  [[ "$keyimg" == "img" ]]
then
  redis-cli get img | sed "s/|/\n/g" | sed "s/^.*,//" >  img_lines.b64
  ypercent=`redis-cli get ypercent`
  color=`redis-cli get color`
  COUNTER=0
  ZERO="0"
  SIGN=""
  TSNAMES=""
  for  i in `cat img_lines.b64`;
  do
    let COUNTER=$COUNTER+1; test $COUNTER -gt 9 && ZERO=''; echo $i | base64 -d > ./img/image_to_zoom.jpg # tmp_f_"$ZERO$COUNTER".jpg;

    isexifrotate=""
    isexifrotate=`identify -format '%[orientation]' ./img/image_to_zoom.jpg`

    if [ "$isexifrotate" == "RightTop" ]
    then
        convert ./img/image_to_zoom.jpg -rotate 90 ./img/rotate_image_to_zoom.jpg
        mv -f ./img/rotate_image_to_zoom.jpg ./img/image_to_zoom.jpg
    fi
    if [ "$isexifrotate" == "LeftBottom" ]
    then
        convert  ./img/image_to_zoom.jpg -rotate 270 ./img/rotate_image_to_zoom.jpg
        mv -f ./img/rotate_image_to_zoom.jpg ./img/image_to_zoom.jpg
    fi
#BottomRight
    if [ "$isexifrotate" == "BottomRight" ]
    then
        convert ./img/image_to_zoom.jpg -rotate 180 ./img/rotate_image_to_zoom.jpg
        mv -f ./img/rotate_image_to_zoom.jpg ./img/image_to_zoom.jpg
    fi

    TEXT=""
    if [ -f TEXT_"$COUNTER" ]
    then
        TEXT=`cat TEXT_"$COUNTER"`
        LENGTH=0;
        FIRST_SIGN="|"
        LENGTH=`echo $TEXT | sed "s/ //g" | wc -c`
        test "$LENGTH" -gt "1" && FIRST_SIGN=`echo $TEXT | head -c 1`
        test "$FIRST_SIGN" == "~" && LENGTH=0

      if [ "$LENGTH" -gt "1" ]
      then
        rm -f ./img/text_image_to_zoom.jpg
        width=`identify -format %w ./img/image_to_zoom.jpg`; height=`identify -format %h ./img/image_to_zoom.jpg`; convert -background '#0008' -fill white -font Roboto-Condensed-Regular -gravity center -geometry +0+$[height*ypercent/100-height/20] -size $[width-width/10]x$[height/10]  caption:"$TEXT" ./img/image_to_zoom.jpg +swap -gravity south -composite ./img/text_image_to_zoom.jpg
      fi
    mv -f ./img/text_image_to_zoom.jpg ./img/image_to_zoom.jpg
    fi

    if [ "$COUNTER" -gt "1" ]
    then
      width2=`identify -format %w ./img/image_to_zoom.jpg`; height2=`identify -format %h ./img/image_to_zoom.jpg`;
      test $height2 -gt $heightFirst && height2=$heightFirst
      test $width2 -gt $widthFirst && width2=$widthFirst
      rm -f ./img/resize_image_to_zoom.jpg
      convert  ./img/image_to_zoom.jpg -resize "$width2"x"$height2>" -gravity center -background "#$color"ff -extent "$widthFirst"x"$heightFirst" ./img/resize_image_to_zoom.jpg
      mv -f ./img/resize_image_to_zoom.jpg ./img/image_to_zoom.jpg
    else
      let widthFirst=`identify -format %w ./img/image_to_zoom.jpg`
      let heightFirst=`identify -format %h ./img/image_to_zoom.jpg`
    fi

    timetext=`redis-cli get sec`
    if [ -f ./zooming/TIME_TEXT_"$COUNTER" ]
    then
      timetext=`cat ./zooming/TIME_TEXT_"$COUNTER"`
    fi

    ffmpeg -loglevel quiet -loop 1 -i ./img/image_to_zoom.jpg -vf "scale=iw*4:ih*4,zoompan=z='if(lte(mod(on,60),30),zoom+0.001,zoom+0.001)':x='iw/2-(iw/zoom)/2':y='ih/2+(ih/zoom)/2':d=25*$timetext" -c:v libx264 -t $timetext -aspect ${widthFirst}:${heightFirst} -s ${widthFirst}x${heightFirst} ./zooming/zoomin_"$ZERO$COUNTER".mp4 -y
#${widthFirst}x${heightFirst}
    ffmpeg -loglevel quiet -y -v quiet -i ./zooming/zoomin_"$ZERO$COUNTER".mp4 -vcodec copy -acodec copy -vbsf h264_mp4toannexb -threads 4 -aspect ${widthFirst}:${heightFirst} -s ${widthFirst}x${heightFirst} ./zooming/zoomin_"$ZERO$COUNTER".ts
    test $COUNTER -eq 2 && SIGN="|"
    TSNAMES="$TSNAMES$SIGN./zooming/zoomin_$ZERO$COUNTER.ts"
  done
  #ffmpeg -loop 1 -i image1.jpg -vf "scale=iw*4:ih*4,zoompan=z='if(lte(mod(on,60),30),zoom+0.001,zoom+0.001)':x='iw/2-(iw/zoom)/2':y='ih/2+(ih/zoom)/2':d=25*5" -c:v libx264 -t 5 -s "1300x765" zoomin.mp4 -y

  filenameMp4=OUTPUT_"$RANDOM"_"$RANDOM".mp4

  rm -f ./m4a/hi.mp4
  ffmpeg -loglevel quiet -y -i ./m4a/hi.wav ./m4a/hi.mp4

  ffmpeg -loglevel quiet -y -v quiet -i concat:"$TSNAMES" -vcodec copy -acodec copy -vbsf:a aac_adtstoasc -threads 4 -aspect ${widthFirst}:${heightFirst} -s ${widthFirst}x${heightFirst} ./zooming/"$filenameMp4"
echo '----------------------------------------------------------------------------------------------'
  echo $widthFirst x $heightFirst
  ffmpeg -loglevel quiet -y -v quiet -i ./zooming/"$filenameMp4" -i ./m4a/hi.mp4 -vcodec copy -acodec copy -vbsf:a aac_adtstoasc -aspect ${widthFirst}:${heightFirst} -s ${widthFirst}x${heightFirst} ~/mp4Downloads/"$filenameMp4"

  unlink ./zooming/"$filenameMp4"

  redis-cli append mp4AllFilenames ",$filenameMp4"
  redis-cli append mp4NewFilenames ",$filenameMp4"

  redis-cli del "img"
fi


for i in $(redis-cli get mp4DelFilenames); do   cd mp4Downloads && rm -f $i ; cd ; done
toDel=$(redis-cli get mp4DelFilenames)
test -n "$toDel" &&  redis-cli del mp4DelFilenames

sleep 1
done
