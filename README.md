# observable_file
Features
  * event `change` when file changes
  * no `change` event if file not exists during work
    * relaunch will cause fail when first read
  * atomic save file
    * write to tmp file
    * replace original
  