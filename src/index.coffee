require 'event_mixin'
fs = require 'fs'
chokidar = require 'chokidar'

class Observable_file
  path    : ''
  _watcher: null
  
  event_mixin @
  constructor:(@path)->
    event_mixin_constructor @
    if !fs.existsSync @path
      fs.writeFileSync @path, "{}"
    @_watcher = chokidar.watch(@path)
    @_watcher.on 'ready', ()=>
      @dispatch "ready"
      @_watcher.on 'all', (ev)=>
        await @get defer(err, data)
        if err
          return perr err
        @dispatch "change", data
        return
      return
    
  
  delete : ()->
    @dispatch "delete"
    @_watcher.close()
  
  # ###################################################################################################
  #    async
  # ###################################################################################################
  get : (cb)->
    await fs.readFile @path, defer(err, data); return cb err if err
    try
      cb null, JSON.parse data
    catch e
      return cb e
    return
  
  set : (data, on_end)->
    write_data = JSON.stringify data
    tmp = @path+".tmp"
    await fs.exists @path, defer(exists)
    if exists
      await fs.readFile @path, defer(err, check_data); return on_end err if err
      if write_data == check_data
        on_end null
        return
    await fs.writeFile tmp, JSON.stringify(data), defer(err); return on_end err if err
    await fs.rename tmp, @path, defer(err); return on_end err if err
    on_end null
    return
  
  # ###################################################################################################
  #    sync
  # ###################################################################################################
  getSync : ()->
    JSON.parse fs.readFileSync @path
  
  setSync : (data)->
    write_data = JSON.stringify data
    if fs.existsSync @path
      check_data = fs.readFileSync @path
      if write_data == check_data
        return
    
    tmp = @path+".tmp"
    fs.writeFileSync tmp, write_data
    fs.renameSync tmp, @path
    return
  

module.exports = Observable_file