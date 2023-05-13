# Qortrollor

## A Qortal Node Controller

### Purposes of this project:

* To allow configuration of a Qortal node with a yaml file.
* To enable the use of systemd to start and stop the node (automatically),
  avoiding the need to manually start the node, when the 'host' reboots.

### Audience

Initially; advanced linux users.
Though part of the idea is that yaml should be more user-friendly to edit than json.

### Why:

* You fancy the idea of having your node started automatically whenever your 'host' boots,
  rather than being inconvenienced to start it manually.
* You would like to be able to edit your node-settings in a format much more aligned with hoomans than json.
* You would like to have ALL the possible settings readily available
  rather than relying on some sporadically updated documentation.

### Synopsis

* This project is a work in progress.
* Any feedback or participation is welcome!
* The audience for this project are those who immediately knows what systemd is,
  or those who at least have some understanding of Linux and a terminal.
* The part of this system concerning systemd is called 'Qystemd'.
* As of now, it is only made for Linux with Bash.
    * Systemd is only required if you want to use qystemd to start and stop the node.
    * Other 'Unixes' with Bash may work, but are not tested.
    * Maybe Other 'Unixes', such as Macos etc. will be supported in the future.
    * Windows is not supported and probably won't ever be.
    * It has been tested on Fedora and (containerized) Debian.
* Your Qortal node directory can be at any location as you desire.

### How to use

* Clone this repo into a directory containing a Qortal node.
    * So that you have the cloned directory 'qortrollor' alongside the file qortal.jar
* Execute the script ./qortrollor/installor.sh
    * The script will offer to exit or install or uninstall:
        * Qortrollor
        * Qystemd
        * Both
    * Qystemd requires that Qortrollor is installed
* Installing will create another directory '_qortrolled' in the 'node_dir'.
* Some existing files will be backed up into '_qortrolled'.
* Some new files will appear:
    * settings.yaml
    * start_qortrollor_manually.sh
    * stop_qortrollor_manually.sh
    * And if qystemd is installed, also:
        * start_qortrollor_systemd.sh
        * stop_qortrollor_systemd.sh
* Use one of the 'start'-scripts to start the node.
* A new settings.json is generated from settings.yaml every time the node starts
* Initially the node will use a default 'lite' config.
    * Thus, it will start quickly and independently of other circumstances such as db usw.
    * Edit the settings.yaml to change this.
    * Your original settings from settings.json will be available in the yaml.
    * See: "Editing Yaml".

### Editing .env

TODO write ...

### Editing Yaml

The yaml can contain multiple configurations.

* If the key 'active_section_name' exists the configuration under that name is used.
* If 'active_section_name' does not exist, the configuration will be assumed to be 'flat'
  ie without 'sections' and only one config.
* The original config from before installation of qortrollor will be available as 'original'.
* So "active_section_name: original" will revert the configuration the original config.
* Thus;
  ```yaml
  active_section_name: original
  ```
* will revert the configuration to the original config.
* Or you can invent a new section name and fiddle.
* Here is the default lite config section as a showcase:
    ```yaml
    active_section_name: lite
    lite:
      lite: true
      uPnPEnabled: false
      apiWhitelist:
        - 127.0.0.1
      minPeerVersion: 4.0.0
      allowConnectionsWithOlderPeerVersions: false
  ```
* The yaml also contains a section 'default', which contains all the parameters
  I could scrape from the java source file 'Settings.java'.
  So you can run amok in experimentation and make a lot of sections ...

### Unstallation:

* When uninstalling qortrollor it is attempted to reinstate the original state of 'node-dir'.
* Except from two remaining directories:
    * 'qortrollor'
    * '_cortrolled'
* Which you can subsequently delete at your leisure.
* NO files are deleted at any time!
* Original files are fetched from ./_qortrolled/backup_when_installed/
* Obsolete files are moved to dated directories under ./_qortrolled/backup_when_uninstalled/
* At any time as you please delete 'backup_when_uninstalled' or stuff therein.
* If however you delete 'backup_when_installed' before unstallation the 'reinstation' will be incomplete.

### Logging:

* Logging is changed.
    * Log-files are now under the directory 'log'.
    * The current log-file will no longer inconveniently change name during a 'session'.
    * Instead the archived log-files are numbered - and compressed.
        * (currently there will be up to 7 such archived log-files,
          because I found it too much to locate the relevant documentation
          for log4j2.properties ... I think a lower number would be appropriate - Inputs are welcome.)
    * The change is achieved by appending this text to the file 'log4j2.properties':
    ```
    # QORTROLLOR:
    appender.rolling.strategy.type=DefaultRolloverStrategy
    appender.rolling.fileName=log/qortal.log
    appender.rolling.filePattern = log/qortal.%i.log.gz
    ```

### Qystemd:

* You don't need to install qystemd initially. It can be additionally installed later with the installor.
* Because qortrollor allows the installation path to be freely chosen,
  and because systemd requires a fixed path for 'ExecStart', and because systemd has convenient mechanisms
  for using the 'xdg' thingy, qystemd uses the directory ~/config/qotrollor.
* When installing qystemd the service is 'enabled' but not 'started'.
    * Thus, the node will not start automatically after installation. But it will after a reboot.
    * You can 'systemd-start' the node with the script 'start_qortrollor_systemd.sh'.
    * But it is probably wise to first check the settings.yaml. and try start/stop manually at first.

#### Systemd-user-services are not started at boot

* Normally you will not run qortal as root, but as some other user.
* If this user is not logging in at boot, then systemd-services for that user will not automatically start.
* This can be enabled, but it requires root access to enable:
  ```Shell
  sudo loginctl enable-linger <USERNAME>
  ```
  Then at boot a login session is created for the specified user,
  and (enabled) systemd-services for this user will start at boot.

### Progress:

* The code is currently littered with out-commented garbage, so cleanage is due.
* So far it has only been tested by me, so if anyone bites, the expected unforeseen snafus are expected
  and code will need according modifications.

### Further:

* No guaranties are given. Everything is "best effort". Please refer to the chosen license.
* Maybe you will want to perform your first endeavours with qortrollor in a
  'fresh' unmodified installation of qortal, before venturing to mangle your beloved investment -
  or you might want to use a copy of your current node to dabble with.
  as qortrollor initially starts with a lite configuration, it does not incur any substantial disk usage.
* Yes. I idiosyncratically name stuffs ending in '-or' rather than '-er'.
    * I have some rational reasons for this ...
    * It is a reference to the movie 'Defendor'.

Keywords: Qortal start stop systemd yaml-config
