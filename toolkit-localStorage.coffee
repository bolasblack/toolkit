((definition) ->
  # requirejs
  if typeof define is "function" and define.amd
    define ["toolkit"], (G) ->
      G.localStorage = definition G
      G
  # CMD and CommandJS
  else if exports?
    G = require "./toolkit"
    if module? and module.exports
      module.exports = G
    else
      exports.G = G
  # normal
  else
    G = @G

  G.localStorage = definition G
) (G) ->
    ls = @localStorage
    ss = @sessionStorage
    document = @document
    useCookie = false
    useSession = false
    storageTime = "30d"

    # [[[ utils
    getInt = (str, hex=10) ->
      return 0 if str is ""
      parseInt str, hex

    parseTime = (str) ->
      timeCount = getInt "#{str}".slice 0, -1
      timeUnit = str.substr -1
      switch timeUnit
        when "s" then timeCount * 1000
        when "m" then timeCount * 60 * 1000
        when "h" then timeCount * 60 * 60 * 1000
        when "d" then timeCount * 24 * 60 * 60 * 1000
        else
          useSession = true
          0

    jsonSafeParse = (str, defaultValue={}) ->
      return defaultValue if not str? or str is ""
      try
        JSON.parse str
      catch error
        defaultValue

    intoObject = (obj, keys, callback) ->
      keys = keys.slice()
      resultObj = obj
      while keys.length > 1
        path = keys.shift()
        resultObj[path] = {} unless resultObj[path]?
        resultObj = resultObj[path]
      callback? resultObj, keys.shift()

    doActionLoop = (actMethod, args) ->
      realArgs = if G.isArray args[0] then args[0] else G.toArray args
      return actMethod realArgs[0] if realArgs.length is 1
      result = {}
      for storageKey in realArgs
        storageValue = actMethod storageKey
        result[storageKey] = storageValue if storageValue?
      result
    # ]]]

    # [[[ cookie
    # s指秒，m指分钟，h指小时，d指天数
    # 如30d代表30天，setCookie "name","hayden","20s"
    setCookie = (key, value, time) ->
      outTime = parseTime time
      cookieStr = "#{key}=#{escape value}"
      currTime = (exp = new Date).setTime exp.getTime() + outTime
      cookieStr += ";expires=#{exp.toGMTString()}" unless useSession
      cookieStr += ";path=/"
      document.cookie = cookieStr

    getCookie = (key) ->
      re = ///(?:;\s*|^)#{key}=(.*?)(?:;|$)///g
      if (result = re.exec document.cookie) then unescape result[1] else null

    delCookie = (key) ->
      cookieValue = getCookie key
      setCookie key, cookieValue, "-1d"
    # ]]]

    # [[[ localStorage
    getLocalStorage = (key) ->
      storage = if useSession then ss else ls
      storage.getItem key

    setLocalStorage = (key, value) ->
      storage = if useSession then ss else ls
      storage.setItem key, value

    delLocalStorage = (key) ->
      storage = if useSession then ss else ls
      storage.removeItem key
    # ]]]

    [setMethod, getMethod, delMethod] = if ls? then \
      [setLocalStorage, getLocalStorage, delLocalStorage] else \
      [setCookie, getCookie, delCookie]

    # ls.set {k1: v1, k2: v2, k3: v3}
    # ls.set k1, v1
    set: ->
      setMethod = setCookie if useCookie
      if G.isPlainObject arguments[0]
        setMethod key, value, storageTime for key, value of arguments[0]
      else
        [key, value] = arguments
        setMethod key, value, storageTime if key? and value?
      this

    # ls.get ['id1', 'id2', 'id3']
    # ls.get 'id1', 'id2', 'id3'
    get: ->
      getMethod = getCookie if useCookie
      doActionLoop getMethod, arguments

    # same as @get()
    del: ->
      delMethod = delCookie if useCookie
      doActionLoop delMethod, arguments
      this

    # {a: {b: {c: {d: 1}
    # getObject "a", "b", "c"
    # => {d: 1}
    getObject: (keys...) ->
      result = originalObject = jsonSafeParse @get keys.shift()
      return result unless keys.length
      intoObject originalObject, keys, (object, key) ->
        result = object[key]
      result

    # {a: {b: {c: {d: 1}
    # setObject "a", "b", "c", "d", 2
    # => {a: {b: {c: {d: 2}
    setObject: (keys..., value) ->
      originalKey = keys.shift()
      originalObject = @getObject originalKey
      intoObject originalObject, keys, (object, key) =>
        if G.isPlainObject object
          object[key] = value
          @set originalKey, JSON.stringify originalObject
        else
          console.warn object + "is not a object"
      this

    storageTime: (time) ->
      if getInt(time) in [0, NaN]
        [storageTime, useSession] = [0, true]
        return this

      time = "#{time}s" if G.isNumber time
      if time.slice(-1) in ["s", "m", "h", "d"]
        [storageTime, useSession] = [time, false]
      this

    useCookie: (boolInput) ->
      return useCookie unless boolInput?
      useCookie = boolInput
      this
