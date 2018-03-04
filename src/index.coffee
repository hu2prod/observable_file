require 'event_mixin'
fs = require 'fs'
chokidar = require 'chokidar'

class Observable_file
  path    : ''
  _watcher: null
  pack    : JSON.stringify
  unpack  : JSON.parse
  _last_raw_data : ''
  truncate_reread_counter : 0
  truncate_reread_max : 10
  
  event_mixin @
  constructor:(@path, opt = {})->
    @pack   = opt.pack    if opt.pack
    @unpack = opt.unpack  if opt.unpack
    
    event_mixin_constructor @
    if !fs.existsSync @path
      fs.writeFileSync @path, @pack {}
    
    @_watcher_restart()
  
  delete : ()->
    @dispatch "delete"
    @_watcher.close()
  
  _watcher_restart : ()->
    first_time = @_watcher == null
    @_watcher?.close()
    
    @_watcher = chokidar.watch(@path)
    @_watcher.on 'ready', ()=>
      if first_time
        @dispatch "ready"
      
      # TODO make for/pull request of chokidar and fix it there
      # https://nodejs.org/docs/latest-v6.x/api/fs.html#fs_inodes
      # https://github.com/paulmillr/chokidar/issues/591 for alternative solution
      @_watcher.on 'raw', (ev)=>
        if ev == 'rename'
          @_watcher_restart()
          @change()
        return
      
      @_watcher.on 'all', (ev)=>
        @change()
        return
      return
  
  change : ()->
    await @get defer(err, data)
    if err
      if @_last_raw_data == ""
        if @truncate_reread_counter < @truncate_reread_max
          @truncate_reread_counter++
          return call_later ()=>@change()
      @truncate_reread_counter = 0
      return perr "WARNING suppress change event due:", err
    @truncate_reread_counter = 0
    @dispatch "change", data
  # ###################################################################################################
  #    async
  # ###################################################################################################
  get : (cb)->
    await fs.readFile @path, 'utf-8', defer(err, data); return cb err if err
    @_last_raw_data = data
    try
      cb null, @unpack data
    catch e
      return cb e
    return
  
  set : (data, on_end)->
    write_data = @pack data
    tmp = @path+".tmp"
    await fs.exists @path, defer(exists)
    if exists
      await fs.readFile @path, 'utf-8', defer(err, check_data); return on_end err if err
      if write_data == check_data
        on_end null
        return
    await fs.writeFile tmp, write_data, defer(err); return on_end err if err
    # http://stupidpythonideas.blogspot.com/2014/07/getting-atomic-writes-right.html
    # recheck data needed because file was not flushed to disk
    # or event race condition
    await fs.readFile tmp, 'utf-8', defer(err, recheck_data); return on_end err if err
    if recheck_data != write_data
      err = new Error """
        WARNING. Write to '#{tmp}' failed for some strange reason (writeFile doesn't throws error).
        You possibly launches 2+ instances that uses single file and they replaced file simultaneously.
        It's probably ok. Data swap prevented because non-valid data can pass to main file
        """
      perr err
      return on_end err
    await fs.rename tmp, @path, defer(err); return on_end err if err
    on_end null
    return
  
  # ###################################################################################################
  #    sync
  # ###################################################################################################
  getSync : ()->
    @unpack @_last_raw_data = fs.readFileSync @path, 'utf-8'
  
  setSync : (data)->
    write_data = @pack data
    if fs.existsSync @path
      check_data = fs.readFileSync @path, 'utf-8'
      if write_data == check_data
        return
    
    tmp = @path+".tmp"
    fs.writeFileSync tmp, write_data
    # http://stupidpythonideas.blogspot.com/2014/07/getting-atomic-writes-right.html
    # recheck data needed because file was not flushed to disk
    # or event race condition
    recheck_data = fs.readFileSync tmp, 'utf-8'
    if recheck_data != write_data
      err = new Error """
        WARNING. Write to '#{tmp}' failed for some strange reason (writeFile doesn't throws error).
        You possibly launches 2+ instances that uses single file and they replaced file simultaneously.
        It's probably ok. Data swap prevented because non-valid data can pass to main file
        """
      perr err
      throw err
    
    fs.renameSync tmp, @path
    return
  

module.exports = Observable_file