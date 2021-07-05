# airsonic_Synology
This project packages the subsonic music server (https://airsonic.github.io) into an installable SPK file for running on Synology NAS devices.  Check the releases tab for the latest version.

# Requirements - Install will fail to complete without these
Synology DSM 6.0 or later (version 7.0+ currently not tested or supported)
Java and Perl packages (install them through package manager first to save time)

# Optional - Install before airsonic if you want them automatically linked to your install
ffmpeg package installed, the default version that ships with the synology is a very old version.
flac and lame pkgs installed if you want to use them as alternate transcoding providers

All requirements can be located either in the package center either through the Synology official repository or the Synocommunity repository

# Notes
This package creates a user called airsonic which is visible in the DSM user interface, you should grant this user access to your music folder.  The airsonic server also runs under this user account.

You can start / stop / restart the airsonic server through the DSM Package manager.  To update to the latest version just grab the spk file from the release page here and do a manual install through the DSM package manager and it will update.

The latest SPK file contains airsonic server 10.6.2.  Check the releases page for current and historical binaries.
