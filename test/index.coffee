assert = require 'assert'
{
  throws
  json_eq
} = require 'fy/test_util'

mod = require '../src/index.coffee'
fs = require 'fs'
file = "./tmp_file"

# Прим в случае fail все тесты могут завалтится по цепочке т.к. не будут удалены watcher'ы
delay = (cb)->setTimeout cb, 100

describe 'index section >', ()->
  describe 'async API >', ()->
    it 'init', ()->
      if fs.existsSync file
        fs.unlinkSync file
    
    it 'first open', ()->
      obs = new mod file
      obs.delete()
      return
    # NO_INSERT
    it 'reopen', (on_end)->
      obs = new mod file
      await obs.get defer(err, data); return on_end err if err
      obs.delete()
      json_eq data, {}
      on_end()
      return
    
    it 'write some', (on_end)->
      obs = new mod file
      await obs.set {a:1}, defer(err); return on_end err if err
      obs.delete()
      on_end()
      return
    # NO_INSERT
    it 'read delayed', (on_end)->
      obs = new mod file
      await obs.get defer(err, data); return on_end err if err
      obs.delete()
      json_eq data, {a:1}
      on_end()
      return
    
    it 'write some; read immidiately', (on_end)->
      obs = new mod file
      await obs.set {b:1}, defer(err); return on_end err if err
      await obs.get defer(err, data); return on_end err if err
      obs.delete()
      json_eq data, {b:1}
      on_end()
      return
    
    it 'remove file + set', (on_end)->
      obs = new mod file
      fs.unlinkSync file
      await obs.set {b:1}, defer(err); return on_end err if err
      obs.delete()
      on_end()
      return
  
  describe 'sync API >', ()->
    it 'init', ()->
      if fs.existsSync file
        fs.unlinkSync file
    
    it 'first open', ()->
      obs = new mod file
      obs.delete()
      return
    # NO_INSERT
    it 'reopen', ()->
      obs = new mod file
      data = obs.getSync()
      obs.delete()
      json_eq data, {}
      return
    
    it 'write some', ()->
      obs = new mod file
      obs.setSync {a:1}
      obs.delete()
      return
    # NO_INSERT
    it 'read delayed', ()->
      obs = new mod file
      data = obs.getSync()
      obs.delete()
      json_eq data, {a:1}
      return
    
    it 'write some; read immidiately', ()->
      obs = new mod file
      obs.setSync {b:1}
      data = obs.getSync()
      obs.delete()
      json_eq data, {b:1}
      return
    
    it 'remove file + set', ()->
      obs = new mod file
      fs.unlinkSync file
      obs.setSync {b:1}
      obs.delete()
      return
    
  describe 'events >', ()->
    describe 'sync >', ()->
      it 'change trigger on self change', (on_end)->
        if fs.existsSync file
          fs.unlinkSync file
        obs = new mod file
        await obs.once "ready", defer()
        fire = 0
        obs.on "change", ()-> fire++
        obs.setSync {b:1}
        await delay defer()
        obs.delete()
        
        assert.equal fire, 1
        on_end()
    
      it 'change trigger on self change multiple', (on_end)->
        if fs.existsSync file
          fs.unlinkSync file
        obs = new mod file
        await obs.once "ready", defer()
        fire = 0
        obs.on "change", ()-> fire++
        obs.setSync {b:1}
        obs.setSync {c:1}
        await delay defer()
        obs.delete()
        
        assert.equal fire, 1
        on_end()
    
      it 'change trigger on self change multiple wait same', (on_end)->
        if fs.existsSync file
          fs.unlinkSync file
        obs = new mod file
        await obs.once "ready", defer()
        fire = 0
        obs.on "change", ()-> fire++
        obs.setSync {b:1}
        await delay defer()
        obs.setSync {b:1}
        await delay defer()
        obs.delete()
        
        assert.equal fire, 1
        on_end()
    
      it 'change trigger on self change multiple wait different', (on_end)->
        if fs.existsSync file
          fs.unlinkSync file
        obs = new mod file
        await obs.once "ready", defer()
        fire = 0
        obs.on "change", ()->fire++
        obs.setSync {b:1}
        await delay defer()
        obs.setSync {c:1}
        await delay defer()
        obs.delete()
        
        assert.equal fire, 2
        on_end()
    
    describe 'async >', ()->
      it 'change trigger on self async change', (on_end)->
        if fs.existsSync file
          fs.unlinkSync file
        obs = new mod file
        await obs.once "ready", defer()
        fire = 0
        obs.on "change", ()-> fire++
        await obs.set {b:1}, defer(err); return on_end err if err
        await delay defer()
        obs.delete()
        
        assert.equal fire, 1
        on_end()
      
      it 'change trigger on self async change multiple same', (on_end)->
        if fs.existsSync file
          fs.unlinkSync file
        obs = new mod file
        await obs.once "ready", defer()
        fire = 0
        obs.on "change", ()-> fire++
        await obs.set {b:1}, defer(err); return on_end err if err
        await delay defer()
        await obs.set {b:1}, defer(err); return on_end err if err
        await delay defer()
        obs.delete()
        
        assert.equal fire, 1
        on_end()
      
      it 'change trigger on self async change multiple different', (on_end)->
        if fs.existsSync file
          fs.unlinkSync file
        obs = new mod file
        await obs.once "ready", defer()
        fire = 0
        obs.on "change", ()->fire++
        await obs.set {b:1}, defer(err); return on_end err if err
        await delay defer()
        await obs.set {c:1}, defer(err); return on_end err if err
        await delay defer()
        obs.delete()
        
        assert.equal fire, 2
        on_end()
      
    
    it 'change trigger on external change', (on_end)->
      if fs.existsSync file
        fs.unlinkSync file
      obs = new mod file
      await obs.once "ready", defer()
      fire = 0
      obs.on "change", ()-> fire++
      fs.writeFileSync file, JSON.stringify {b:1}
      await delay defer()
      obs.delete()
      
      assert.equal fire, 1
      on_end()
    
    it 'no change trigger on self sync change no wait', (on_end)->
      if fs.existsSync file
        fs.unlinkSync file
      obs = new mod file
      await obs.once "ready", defer()
      fire = 0
      obs.on "change", ()-> fire++
      obs.setSync {b:1}
      obs.delete()
      
      assert.equal fire, 0
      on_end()
    
    it 'no change trigger on self sync change no ready', (on_end)->
      if fs.existsSync file
        fs.unlinkSync file
      obs = new mod file
      # await obs.once "ready", defer()
      fire = 0
      obs.on "change", ()-> fire++
      obs.setSync {b:1}
      await delay defer()
      obs.delete()
      
      assert.equal fire, 0
      on_end()
    
    it 'no change trigger on external change if not ready', (on_end)->
      if fs.existsSync file
        fs.unlinkSync file
      obs = new mod file
      fire = 0
      obs.on "change", ()-> fire++
      fs.writeFileSync file, JSON.stringify {b:1}
      await delay defer()
      obs.delete()
      
      assert.equal fire, 0
      on_end()
    
    it 'no change trigger if no contents change', (on_end)->
      obs = new mod file
      await obs.once "ready", defer()
      obs.setSync {c:1}
      await delay defer()
      fire = 0
      obs.on "change", ()-> fire++
      obs.setSync {c:1}
      await delay defer()
      obs.delete()
      
      assert.equal fire, 0
      on_end()
      
    it 'no change trigger on file delete', (on_end)->
      obs = new mod file
      await obs.once "ready", defer()
      await obs.set {c:1}, defer(err); return on_end err if err
      await delay defer()
      fire = 0
      obs.on "change", ()-> fire++
      fs.unlinkSync file
      await delay defer()
      obs.delete()
      
      assert.equal fire, 0
      on_end()
      
    it 'no change trigger on file corrupt', (on_end)->
      obs = new mod file
      await obs.once "ready", defer()
      await obs.set {c:1}, defer(err); return on_end err if err
      await delay defer()
      fire = 0
      obs.on "change", ()-> fire++
      fs.writeFileSync file, 'corrupt'
      await delay defer()
      obs.delete()
      
      assert.equal fire, 0
      on_end()
      
      
  
  describe 'errors >', ()->
    it 'corrupt file open async', (on_end)->
      fs.writeFileSync file, 'corrupt'
      obs = new mod file
      await obs.get defer(err, data)
      obs.delete()
      assert err
      on_end()
      
    it 'corrupt file open sync', ()->
      fs.writeFileSync file, 'corrupt'
      obs = new mod file
      throws ()->
        obs.getSync()
      obs.delete()
    
    it 'file with no read permission'
      
  
  describe 'finish >', ()->
    it 'finish', ()->
      fs.unlinkSync file
  