# BYODA-Variant

Supposed to generate a Variant of the BYODA application to be able to run multiple BYODA in parallel.

Attention: Current Version starts fine and seems to work, but pairing with a transmitter 
does not work, the process terminates after 30 minutes of unsuccessful scanning.

# Prerequisites
* Linux System with Bash
* Java
* `convert` command from ImageMagick 
* BYODA APK file
* Java Keystore to sign the Variant APK file (can be the same that is used for "Build Signed APK" command in Android Studio)

# Usage
Usage: `./Create_BYODA_Variant.sh <Filename of BYODA apk> <Variant number (1-9)> <Optional: Directory name>`

Example to generate Variant 2 of the BYODA.apk application: `./Create_BYODA_Variant.sh BYODA.apk 2`

