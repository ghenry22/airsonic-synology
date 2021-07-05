#!/bin/sh
. /etc/profile
TEMP_FOLDER="`find / -maxdepth 2 -name '@tmp' | head -n 1`"
PID=""

airsonic_get_pid ()
{
    PID=`ps -ax | grep java | grep airsonic | head -n 1 | awk '{print $1}'`
    echo "$(date +%d.%m.%y_%H:%M:%S): looking for PID" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
}

preinst ()
{
    . /etc/profile

    ########################################
    #check if Java is installed

    if [ -z ${JAVA_HOME} ]; then
        echo "Java is not installed or not properly configured. JAVA_HOME is not defined. " > $SYNOPKG_TEMP_LOGFILE
            echo "Download and install the Java Synology package from http://wp.me/pVshC-z5" >> $SYNOPKG_TEMP_LOGFILE
            echo "$(date +%d.%m.%y_%H:%M:%S): Download and install the Java Synology package from http://wp.me/pVshC-z5" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
        exit 1
    fi

    if [ ! -f ${JAVA_HOME}/bin/java ]; then
        echo "Java is not installed or not properly configured. The Java binary could not be located. " > $SYNOPKG_TEMP_LOGFILE
            echo "Download and install the Java Synology package from http://wp.me/pVshC-z5" >> $SYNOPKG_TEMP_LOGFILE
            echo "$(date +%d.%m.%y_%H:%M:%S): Download and install the Java Synology package from http://wp.me/pVshC-z5" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
        exit 1
    else
        echo "$(date +%d.%m.%y_%H:%M:%S): found Java in ${JAVA_HOME}" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
    fi
    
    #########################################
    #is the User Home service enabled?
	
	UH_SERVICE=`synogetkeyvalue /etc/synoinfo.conf userHomeEnable`
    if [ ${UH_SERVICE} == "no" ]; then
        echo "The User Home service is not enabled. Please enable this feature in the User control panel in DSM." >> $SYNOPKG_TEMP_LOGFILE
        echo "The User Home service is not enabled. Please enable this feature in the User control panel in DSM." >> ${SYNOPKG_PKGDEST}/airsonic_package.log
        exit 1
    else 
        echo "$(date +%d.%m.%y_%H:%M:%S): User home is enabled" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
    fi
    
    exit 0
}

postinst ()
{
    #create airsonic daemon user
    synouser --add airsonic `${SYNOPKG_PKGDEST}/passgen 1 20` "airsonic daemon user" 0 "" ""
	sleep 3
    echo "$(date +%d.%m.%y_%H:%M:%S): create airsonic daemon user" >> ${SYNOPKG_PKGDEST}/airsonic_package.log

    #determine the airsonic user homedir and save that variable in the user's profile
    #this is needed because librtmp needs to write a file called ~/.swfinfo
    #and new users seem to inherit a HOME value of /root which they have no permissions for
    AIRSONIC_HOMEDIR=`cat /etc/passwd | sed -r '/airsonic daemon user/!d;s/^.*:airsonic daemon user:(.*):.*$/\1/'`
    su - airsonic -s /bin/sh -c "echo export HOME=${AIRSONIC_HOMEDIR} >> .profile"

    
    #link transcoders
    if [ ! -d  ${SYNOPKG_PKGDEST}/transcode ]; then
        mkdir ${SYNOPKG_PKGDEST}/transcode
        echo "$(date +%d.%m.%y_%H:%M:%S): created transcode directory" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
    fi

    #use the flac pkg
    if [ -f /usr/local/bin/flac ]; then
        ln -s /usr/local/bin/flac ${SYNOPKG_PKGDEST}/transcode/flac
        echo "$(date +%d.%m.%y_%H:%M:%S): Linked flac file to flac pkg" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
    fi

    #use lame pkg
    if [ -f /usr/local/bin/lame ]; then
        ln -s /usr/local/bin/lame ${SYNOPKG_PKGDEST}/transcode/lame
        echo "$(date +%d.%m.%y_%H:%M:%S): Linked flac file to flac pkg" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
    fi

    #use the ffmpeg from synocommunity
    if [ -f /usr/local/ffmpeg/bin/ffmpeg ]; then
        ln -s /usr/local/ffmpeg/bin/ffmpeg ${SYNOPKG_PKGDEST}/transcode/ffmpeg
        echo "$(date +%d.%m.%y_%H:%M:%S): Linked ffmpeg file to ffmpeg synocommunity pkg" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
    
    #use the ffmpeg from serviio if available
    elif [ -f /var/packages/Serviio/target/bin/ffmpeg ]; then
        ln -s /var/packages/Serviio/target/bin/ffmpeg ${SYNOPKG_PKGDEST}/transcode/ffmpeg
        echo "$(date +%d.%m.%y_%H:%M:%S): Linked ffmpeg file to Serviio" >> ${SYNOPKG_PKGDEST}/airsonic_package.log

    #use the ffmpeg from synology
    elif [ -f /usr/bin/ffmpeg ]; then
        ln -s /usr/bin/ffmpeg ${SYNOPKG_PKGDEST}/transcode/ffmpeg
        echo "$(date +%d.%m.%y_%H:%M:%S): Linked ffmpeg file to internal Synology ffmpeg " >> ${SYNOPKG_PKGDEST}/airsonic_package.log
    fi
	
    #########################################
    ##start airsonic
    #fix file permissions
    chmod +x ${SYNOPKG_PKGDEST}/airsonic.sh
    chmod 775 ${SYNOPKG_PKGDEST}/airsonic-booter-jar-with-dependencies.jar
    chmod 775 ${SYNOPKG_PKGDEST}/airsonic.war
    chown -R airsonic:users ${SYNOPKG_PKGDEST}
    echo "$(date +%d.%m.%y_%H:%M:%S): start airsonic for first initialisation" >> ${SYNOPKG_PKGDEST}/airsonic_package.log

    #set up symlink for the DSM GUI
    ln -s ${SYNOPKG_PKGDEST}/ /usr/syno/synoman/webman/3rdparty/airsonic
            
    #create custom temp folder so temp files can be bigger
    if [ ! -d ${SYNOPKG_PKGDEST}/../../@tmp/airsonic ]; then
        mkdir ${SYNOPKG_PKGDEST}/../../@tmp/airsonic
        chown -R airsonic ${SYNOPKG_PKGDEST}/../../@tmp/airsonic
    fi
    #create symlink to the created directory
    if [ ! -L /tmp/airsonic ]; then
        ln -s ${SYNOPKG_PKGDEST}/../../@tmp/airsonic /tmp/
    fi

    #start airsonic as airsonic user
    su - airsonic -s /bin/sh -c /usr/syno/synoman/webman/3rdparty/airsonic/airsonic.sh

    sleep 10
    
    airsonic_get_pid
    if [ ! -z $PID ]; then
        echo "$(date +%d.%m.%y_%H:%M:%S): started airsonic successfully. PID is: $PID" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
    else
        echo "Error: Can not start airsonic during install" >> $SYNOPKG_TEMP_LOGFILE
        echo "$(date +%d.%m.%y_%H:%M:%S): Error: Can not start airsonic during install" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
        exit 1
    fi

    #give it some time to start up
    sleep 120

    #stop airsonic

    kill $PID
    sleep 5
    echo "$(date +%d.%m.%y_%H:%M:%S): Stopped airsonic" >> ${SYNOPKG_PKGDEST}/airsonic_package.log

    #delete symlink
    rm /usr/syno/synoman/webman/3rdparty/airsonic
    #delete temp files
    if [ -d ${SYNOPKG_PKGDEST}/../../@tmp/airsonic ]; then
        rm -r ${SYNOPKG_PKGDEST}/../../@tmp/airsonic
    fi

    echo "$(date +%d.%m.%y_%H:%M:%S): ----installation complete----" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
    exit 0
}

preuninst ()
{
    ##############################################
    #stop airsonic if it is running

    airsonic_get_pid
    if [ -z $PID ]; then
        sleep 1
    else
        echo "$(date +%d.%m.%y_%H:%M:%S): stopping airsonic" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
        kill $PID
        sleep 5
        if [ -L /usr/syno/synoman/webman/3rdparty/airsonic ]; then
            rm /usr/syno/synoman/webman/3rdparty/airsonic
        fi

        if [ -d ${SYNOPKG_PKGDEST}/../../@tmp/airsonic ]; then
            rm -r ${SYNOPKG_PKGDEST}/../../@tmp/airsonic
        fi
    fi

    exit 0
}

postuninst ()
{
    synouser --del airsonic

    #remove DSM icon symlink
    if [ -L /usr/syno/synoman/webman/3rdparty/airsonic ]; then
        rm /usr/syno/synoman/webman/3rdparty/airsonic
    fi

    #remove temp symlink
    rm /tmp/airsonic

    exit 0
}

preupgrade ()
{
    ##############################
    #stop airsonic if it is runing
    
    airsonic_get_pid
    if [ ! -z $PID ]; then 
        echo "$(date +%d.%m.%y_%H:%M:%S): stopping airsonic for upgrade" >> ${SYNOPKG_PKGDEST}/airsonic_package.log
        kill $PID
        sleep 5
    fi

    #create temporary storage for db and settings backup
    if [ ! -d  ${SYNOPKG_PKGDEST}/../../@tmp/airsonic_upgrade ]; then
        mkdir ${SYNOPKG_PKGDEST}/../../@tmp/airsonic_upgrade
        chown -R airsonic ${SYNOPKG_PKGDEST}/../../@tmp/airsonic_upgrade
    fi

    #backup settings and db
    cp ${SYNOPKG_PKGDEST}/airsonic.properties ${SYNOPKG_PKGDEST}/../../@tmp/airsonic_upgrade/
    cp -R ${SYNOPKG_PKGDEST}/db ${SYNOPKG_PKGDEST}/../../@tmp/airsonic_upgrade/
    cp -R ${SYNOPKG_PKGDEST}/lucene2 ${SYNOPKG_PKGDEST}/../../@tmp/airsonic_upgrade/
    echo "$(date +%d.%m.%y_%H:%M:%S): backed up database and settings" >> ${SYNOPKG_PKGDEST}/airsonic_package.log

    #remove the airsonic temp directory
    if [ -d ${SYNOPKG_PKGDEST}/../../@tmp/airsonic ]; then
        rm -r ${SYNOPKG_PKGDEST}/../../@tmp/airsonic
    fi

    exit 0
}

postupgrade ()
{

    #restore database and config
    cp ${SYNOPKG_PKGDEST}/../../@tmp/airsonic_upgrade/airsonic.properties ${SYNOPKG_PKGDEST}/airsonic.properties
    cp -R ${SYNOPKG_PKGDEST}/../../@tmp/airsonic_upgrade/db ${SYNOPKG_PKGDEST}/
    cp -R ${SYNOPKG_PKGDEST}/../../@tmp/airsonic_upgrade/lucene2 ${SYNOPKG_PKGDEST}/
    echo "$(date +%d.%m.%y_%H:%M:%S): restored database and settings" >> ${SYNOPKG_PKGDEST}/airsonic_package.log

    remove upgrade temp storage
    if [ -d  ${SYNOPKG_PKGDEST}/../../@tmp/airsonic_upgrade ]; then
        rm -rf ${SYNOPKG_PKGDEST}/../../@tmp/airsonic_upgrade
    fi

    #airsonic may not own all new files
    chown -R airsonic ${SYNOPKG_PKGDEST}/

    #make the airsonic start script executable
    chmod +x ${SYNOPKG_PKGDEST}/airsonic.sh 

    echo "$(date +%d.%m.%y_%H:%M:%S): ----update complete----" >> ${SYNOPKG_PKGDEST}/airsonic_package.log

    exit 0
}
