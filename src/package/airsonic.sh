#!/bin/sh

###################################################################################
#   version: 1.0.1062
#   Shell script for starting airsonic.  
#   Author: Sindre Mehus, Gigon, Madevil, Gaven Henry
###################################################################################


RAM=$((`free | grep Mem: | sed -e "s/^ *Mem: *\([0-9]*\).*$/\1/"`/1024))
if [ $RAM -le 129 ]; then
    AIRSONIC_INIT_MEMORY=32
    AIRSONIC_MAX_MEMORY=80
elif [ $RAM -le 257 ]; then
    AIRSONIC_INIT_MEMORY=64
    AIRSONIC_MAX_MEMORY=192
elif [ $RAM -le 1025 ]; then
    AIRSONIC_INIT_MEMORY=128
    AIRSONIC_MAX_MEMORY=192
elif [ $RAM -le 2049 ]; then
    AIRSONIC_INIT_MEMORY=256
    AIRSONIC_MAX_MEMORY=256
elif [ $RAM -gt 2048 ]; then
    AIRSONIC_INIT_MEMORY=256
    AIRSONIC_MAX_MEMORY=512
fi

AIRSONIC_HOME=/usr/syno/synoman/webman/3rdparty/airsonic
AIRSONIC_HOST=0.0.0.0
AIRSONIC_PORT=4040
AIRSONIC_HTTPS_PORT=0
AIRSONIC_CONTEXT_PATH=/
AIRSONIC_PIDFILE=/usr/syno/synoman/webman/3rdparty/airsonic/PID.log
AIRSONIC_DEFAULT_MUSIC_FOLDER=/volume1/Public/Media/Artists
AIRSONIC_DEFAULT_UPLOAD_FOLDER=/volume1/Public/Media/incoming
AIRSONIC_DEFAULT_PODCAST_FOLDER=/volume1/Public/Media/podcast
AIRSONIC_DEFAULT_PLAYLIST_IMPORT_FOLDER=/volume1/Public/Media/Playlists/Import
AIRSONIC_DEFAULT_PLAYLIST_EXPORT_FOLDER=/volume1/Public/Media/Playlists/Export
AIRSONIC_DEFAULT_PLAYLIST_BACKUP_FOLDER=/volume1/Public/Media/Playlists/Backup
AIRSONIC_DEFAULT_TRANSCODE_FOLDER=/usr/syno/bin
AIRSONIC_DEFAULT_TIMEZONE=
AIRSONIC_UPDATE=false
AIRSONIC_GZIP=
AIRSONIC_DB=
quiet=0

usage() {
    echo "Usage: airsonic.sh [options]"
    echo "  --help                                This small usage guide."
    echo "  --home=DIR                            The directory where airsonic will create files."
    echo "                                        Make sure it is writable. Default: /var/airsonic"
    echo "  --host=HOST                           The host name or IP address on which to bind airsonic."
    echo "                                        Only relevant if you have multiple network interfaces and want"
    echo "                                        to make airsonic available on only one of them. The default value"
    echo "                                        will bind airsonic to all available network interfaces. Default: 0.0.0.0"
    echo "  --port=PORT                           The port on which airsonic will listen for"
    echo "                                        incoming HTTP traffic. Default: 4040"
    echo "  --https-port=PORT                     The port on which airsonic will listen for"
    echo "                                        incoming HTTPS traffic. Default: 0 (disabled)"
    echo "  --context-path=PATH                   The context path, i.e., the last part of the airsonic"
    echo "                                        URL. Typically '/' or '/airsonic'. Default '/'"
    echo "  --init-memory=MB                      The memory initial size (Init Java heap size) in megabytes." 
    echo "                                        Default: 192"
    echo "  --max-memory=MB                       The memory limit (max Java heap size) in megabytes." 
    echo "                                        Default: 384"
    echo "  --pidfile=PIDFILE                     Write PID to this file."
    echo "                                        Default not created."
    echo "  --default-music-folder=DIR            Configure airsonic to use this folder for music."
    echo "                                        This option only has effect the first time airsonic is started." 
    echo "                                        Default '/var/media/artists'"
    echo "  --default-upload-folder=DIR           Configure airsonic to use this folder for music."
    echo "                                        Default '/var/media/incoming'"
    echo "  --default-podcast-folder=DIR          Configure airsonic to use this folder for Podcasts."
    echo "                                        Default '/var/media/podcast'"
    echo "  --default-playlist-import-folder=DIR  Configure airsonic to use this folder for playlist import."
    echo "                                        Default '/var/media/playlists/import'"
    echo "  --default-playlist-export-folder=DIR  Configure airsonic to use this folder for playlist export."
    echo "                                        Default '/var/media/playlists/export'"
    echo "  --default-playlist-backup-folder=DIR  Configure airsonic to use this folder for playlist backup."
    echo "                                        Default '/var/media/playlists/backup'"
    echo "  --default-transcode-folder=DIR        Configure airsonic to use this folder for transcoder."
    echo "  --timezone=Zone/City                  Configure airsonic to use other timezone for time correction"
    echo "                                        Example 'Europe/Vienna', 'US/Central', 'America/New_York'"
    echo "  --db=JDBC_URL                         Use alternate database. MySQL and HSQL are currently supported."
    echo "  --update=VALUE                        Configure airsonic to look in folder /update for updates. Default 'true'"
    echo "  --gzip=VALUE                          Configure airsonic to use Gzip compression. Default 'true'"
    echo "  --quiet                               Don't print anything to standard out. Default false."
    exit 1 
}

# Parse arguments.
while [ $# -ge 1 ]; do
    case $1 in
        --help)
            usage
            ;;
        --home=?*)
            AIRSONIC_HOME=${1#--home=}
            ;;
        --host=?*)
            AIRSONIC_HOST=${1#--host=}
            ;;
        --port=?*)
            AIRSONIC_PORT=${1#--port=}
            ;;
        --https-port=?*)
            AIRSONIC_HTTPS_PORT=${1#--https-port=}
            ;;
        --context-path=?*)
            AIRSONIC_CONTEXT_PATH=${1#--context-path=}
            ;;
        --init-memory=?*)
            AIRSONIC_INIT_MEMORY=${1#--init-memory=}
            ;;
        --max-memory=?*)
            AIRSONIC_MAX_MEMORY=${1#--max-memory=}
            ;;
        --pidfile=?*)
            AIRSONIC_PIDFILE=${1#--pidfile=}
            ;;
        --default-music-folder=?*)
            AIRSONIC_DEFAULT_MUSIC_FOLDER=${1#--default-music-folder=}
            ;;
        --default-upload-folder=?*)
            AIRSONIC_DEFAULT_UPLOAD_FOLDER=${1#--default-upload-folder=}
            ;;
        --default-podcast-folder=?*)
            AIRSONIC_DEFAULT_PODCAST_FOLDER=${1#--default-podcast-folder=}
            ;;
        --default-playlist-import-folder=?*)
            AIRSONIC_DEFAULT_PLAYLIST_IMPORT_FOLDER=${1#--default-playlist-import-folder=}
            ;;
        --default-playlist-export-folder=?*)
            AIRSONIC_DEFAULT_PLAYLIST_EXPORT_FOLDER=${1#--default-playlist-export-folder=}
            ;;
        --default-playlist-backup-folder=?*)
            AIRSONIC_DEFAULT_PLAYLIST_BACKUP_FOLDER=${1#--default-playlist-backup-folder=}
            ;;
        --default-transcode-folder=?*)
            AIRSONIC_DEFAULT_TRANSCODE_FOLDER=${1#--default-transcode-folder=}
            ;;
        --timezone=?*)
           AIRSONIC_DEFAULT_TIMEZONE=${1#--timezone=}
           ;;
        --update=?*)
           AIRSONIC_UPDATE=${1#--update=}
           ;;           
        --gzip=?*)
           AIRSONIC_GZIP=${1#--gzip=}
           ;;
        --db=?*)
            AIRSONIC_DB=${1#--db=}
           ;;
        --quiet)
            quiet=1
            ;;
        *)
            usage
            ;;
    esac
    shift
done

# Use JAVA_HOME if set, otherwise assume java is in the path.
JAVA=java
if [ -e "${JAVA_HOME}" ]
    then
    JAVA=${JAVA_HOME}/bin/java
fi

# Create airsonic home directory.
mkdir -p ${AIRSONIC_HOME}
LOG=${AIRSONIC_HOME}/airsonic_sh.log
rm -f ${LOG}

cd $(dirname $0)
if [ -L $0 ] && ([ -e /bin/readlink ] || [ -e /usr/bin/readlink ]); then
    cd $(dirname $(readlink $0))
fi

${JAVA} -Xms${AIRSONIC_INIT_MEMORY}m -Xmx${AIRSONIC_MAX_MEMORY}m \
  -Dairsonic.home=${AIRSONIC_HOME} \
  -Dserver.address=${AIRSONIC_HOST} \
  -Dserver.port=${AIRSONIC_PORT} \
  -Dairsonic.httpsPort=${AIRSONIC_HTTPS_PORT} \
  -Dserver.context-path=${AIRSONIC_CONTEXT_PATH} \
  -Dairsonic.defaultMusicFolder=${AIRSONIC_DEFAULT_MUSIC_FOLDER} \
  -Dairsonic.defaultUploadFolder=${AIRSONIC_DEFAULT_UPLOAD_FOLDER} \
  -Dairsonic.defaultPodcastFolder=${AIRSONIC_DEFAULT_PODCAST_FOLDER} \
  -Dairsonic.defaultPlaylistImportFolder=${AIRSONIC_DEFAULT_PLAYLIST_IMPORT_FOLDER} \
  -Dairsonic.defaultPlaylistExportFolder=${AIRSONIC_DEFAULT_PLAYLIST_EXPORT_FOLDER} \
  -Dairsonic.defaultPlaylistBackupFolder=${AIRSONIC_DEFAULT_PLAYLIST_BACKUP_FOLDER} \
  -Dairsonic.defaultTranscodeFolder=${AIRSONIC_DEFAULT_TRANSCODE_FOLDER} \
  -Duser.timezone=${AIRSONIC_DEFAULT_TIMEZONE} \
  -Dairsonic.update=${AIRSONIC_UPDATE} \
  -Dairsonic.gzip=${AIRSONIC_GZIP} \
  -Dairsonic.db="${AIRSONIC_DB}" \
  -Djava.awt.headless=true \
  -Djava.net.preferIPv4Stack=true \
  -jar airsonic.war > ${LOG} 2>&1 &
  sleep 5

# Write pid to pidfile if it is defined.
if [ $AIRSONIC_PIDFILE ]; then
    echo $! > ${AIRSONIC_PIDFILE}
fi

if [ $quiet = 0 ]; then
    echo Started airsonic [PID $!, ${LOG}]
fi
