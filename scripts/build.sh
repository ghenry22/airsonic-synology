mkdir ../build/buildtemp
cp -R -v ../src/* ../build/buildtemp/
cd ../build/buildtemp/package
tar -cvzf package.tgz *
cp package.tgz ../
cd ..
rm -rf ./package
tar -cvf ../airsonic1.0.1101.spk *
cd ../../scripts
rm -rf ../build/buildtemp
