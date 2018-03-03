require 'event_mixin'
fs = require 'fs'
chokidar = require 'chokidar'

class Observable_file
  path    : ''
  _watcher: null
  # _last_debounce_ts : 0
  pack : JSON.stringify
  unpack : JSON.parse
  
  event_mixin @
  constructor:(@path)->
    event_mixin_constructor @
    if !fs.existsSync @path
      fs.writeFileSync @path, "{}"
    
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
      return perr "WARNING suppress change event due:", err
    @dispatch "change", data
  # ###################################################################################################
  #    async
  # ###################################################################################################
  get : (cb)->
    await fs.readFile @path, defer(err, data); return cb err if err
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
    await fs.rename tmp, @path, defer(err); return on_end err if err
    on_end null
    return
  
  # ###################################################################################################
  #    sync
  # ###################################################################################################
  getSync : ()->
    @unpack fs.readFileSync @path
  
  setSync : (data)->
    write_data = @pack data
    if fs.existsSync @path
      check_data = fs.readFileSync @path, 'utf-8'
      if write_data == check_data
        return
    
    tmp = @path+".tmp"
    fs.writeFileSync tmp, write_data
    fs.renameSync tmp, @path
    return
  

module.exports = Observable_file