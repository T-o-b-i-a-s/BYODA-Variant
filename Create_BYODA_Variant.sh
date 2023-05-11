#!/bin/bash

KEYSTORE="keystore.jks"      # Set to name of your keystore
KEYALIAS="keyname"           # Set to name of Alias of the key to use

minVar=1
maxVar=9

if [ -z "$1" ]; then
   echo "Script to create a Variant of the BYODA app that are able to run in parralel to each other and to the source app."
   echo
   echo "The script will create a new sub-directory to the current directory to store temporary files and teh final modified APK."
   echo
   echo "Usage: $0 <Filename of BYODA apk> <Variant number ($minVar-$maxVar)> <Optional: Directory name>"
   exit 1
fi


if [ -f "$1" ]; then
   if  [ $2 -ge $minVar ] && [ $2 -le $maxVar ]; then
      if [ -z "$3" ]; then
         tmpdir="BYODA_Var$2"
         if [ -d tmpdir ]; then
            d=$(date +%Y-%m-%d-%H-%M-%S)
            tmpdir="$tmpdir_$d"
         fi
      else
         if [ -d "$3" ]; then
             echo "Directory $3 already exists, please provide a name of a directory that can be created."
             exit 1
         else
            tmpdir="$3"
         fi
      fi
   else
      echo "Variant number given was $2. Please supply a variant number as second parameter between $minVar and $maxVar."
      exit 1
   fi
else
   echo "The BYODA file named $1 does not exist."
   exit 1
fi

echo "We are creating Variant $2 of $1 with output in directory $tmpdir"

mkdir $tmpdir
if [ ! -d "$tmpdir" ]; then
   echo "Error creating directory $tmpdir"
   exit 0
fi

if [ ! -f "apktool.jar" ]; then
   wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.7.0.jar -O apktool.jar
   if [ ! -f "apktool.jar" ]; then
      echo "Error downloading apktool."
      exit 1
   fi
fi

if [ ! -f "uber-apk-signer.jar" ]; then
   wget https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar -O uber-apk-signer.jar
   if [ ! -f "uber-apk-signer.jar" ]; then
      echo "Error downloading Uber APK Signer."
      exit 1
   fi
fi

java -jar apktool.jar d $1 -o $tmpdir/decompiled/

OLDNAME="dexcom"
NEWNAME="dexdrop$2"

ENDING=`grep -oP -m 1 '\.g6\.region.\.(mgdl|mmol)' $tmpdir/decompiled/AndroidManifest.xml`
ENDINGESCAPED=${ENDING//./\\.}

#echo "$ENDINGESCAPED"

OLDMANIFESTSTRING="com\.$OLDNAME$ENDINGESCAPED"
NEWMANIFESTSTRING="com\.$NEWNAME$ENDINGESCAPED"

echo "Updating Manifest ..."

sed -i "s/$OLDMANIFESTSTRING/$NEWMANIFESTSTRING/g" $tmpdir/decompiled/AndroidManifest.xml

# Current APKTool seems to not work properly with the usesPermissionFlags option, so remove it for now
sed -i "s/<uses\-permission android\:name=\"android\.permission\.BLUETOOTH_SCAN\" android\:usesPermissionFlags=\"0x00010000\"\/>/<uses\-permission android\:name=\"android\.permission\.BLUETOOTH_SCAN\"\/>/g" $tmpdir/decompiled/AndroidManifest.xml

OLDAPKTOOLSTRING="renameManifestPackage\: null"
NEWAPKTOOLSTRING="renameManifestPackage\: com\.$NEWNAME$ENDINGESCAPED"

#echo "s/$OLDAPKTOOLSTRING/$NEWAPKTOOLSTRING/g"

sed -i "s/$OLDAPKTOOLSTRING/$NEWAPKTOOLSTRING/g" $tmpdir/decompiled/apktool.yml

echo "Replacing class names and internal references to class names ..."

mv $tmpdir/decompiled/smali/com/$OLDNAME $tmpdir/decompiled/smali/com/$NEWNAME
mv $tmpdir/decompiled/smali_classes3/com/$OLDNAME $tmpdir/decompiled/smali_classes3/com/$NEWNAME

grep -rl Lcom/$OLDNAME/ $tmpdir/decompiled | xargs sed -i "s/Lcom\/$OLDNAME\//Lcom\/$NEWNAME\//g"
grep -rl com\.$OLDNAME\. $tmpdir/decompiled | xargs sed -i "s/com\.$OLDNAME\./com\.$NEWNAME\./g"
grep -rl \$com\$$OLDNAME $tmpdir/decompiled | xargs sed -i "s/\$com\$$OLDNAME/\$com\$$NEWNAME/g"

grep -rl '<string name="app_name">Dexcom G6</string>' $tmpdir/decompiled | xargs sed -i "s/<string name=\"app_name\">Dexcom G6<\/string>/<string name=\"app_name\">Dexcom G6 Var$2<\/string>/g"


# Generate Images

echo "Gernerating Images ..."

convert $tmpdir/decompiled/res/drawable-xxxhdpi/ic_app_mgdl.png -pointsize 58 -fill white -annotate +80+105 "$2" $tmpdir/ic_app_mgdl.png
convert $tmpdir/decompiled/res/drawable-xxxhdpi/ic_app_mmoll.png -pointsize 58 -fill white -annotate +80+105 "$2" $tmpdir/ic_app_mmoll.png

cp $tmpdir/ic_app_mgdl.png $tmpdir/decompiled/res/drawable-xxxhdpi/ic_app_mgdl.png
cp $tmpdir/ic_app_mmoll.png $tmpdir/decompiled/res/drawable-xxxhdpi/ic_app_mmoll.png 

convert $tmpdir/ic_app_mgdl.png -resize 48x48 $tmpdir/decompiled/res/drawable-mdpi/ic_app_mgdl.png
convert $tmpdir/ic_app_mmoll.png -resize 48x48 $tmpdir/decompiled/res/drawable-mdpi/ic_app_mmoll.png

convert $tmpdir/ic_app_mgdl.png -resize 72x72 $tmpdir/decompiled/res/drawable-hdpi/ic_app_mgdl.png
convert $tmpdir/ic_app_mmoll.png -resize 72x72 $tmpdir/decompiled/res/drawable-hdpi/ic_app_mmoll.png

convert $tmpdir/ic_app_mgdl.png -resize 96x96 $tmpdir/decompiled/res/drawable-xhdpi/ic_app_mgdl.png
convert $tmpdir/ic_app_mmoll.png -resize 96x96 $tmpdir/decompiled/res/drawable-xhdpi/ic_app_mmoll.png

convert $tmpdir/ic_app_mgdl.png -resize 144x144 $tmpdir/decompiled/res/drawable-xxhdpi/ic_app_mgdl.png
convert $tmpdir/ic_app_mmoll.png -resize 144x144 $tmpdir/decompiled/res/drawable-xxhdpi/ic_app_mmoll.png

echo "Recompiling APK ..."

java -jar apktool.jar b $tmpdir/decompiled/ -o $tmpdir/BYODA_Var$2.apk
java -jar uber-apk-signer.jar -a $tmpdir/BYODA_Var$2.apk --ks $KEYSTORE --ksAlias $KEYALIAS -o $tmpdir/SignedAPK/

echo "The new APK can be found in directory $tmpdir/SignedAPK/"
ls -la $tmpdir/SignedAPK/*.apk

