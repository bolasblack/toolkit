((window, document)->
  [OP, AP] = [Object.prototype, Array.prototype]

  G = (queryId) -> document.getElementById queryId
  G.t = (tagName) -> document.getElementsByTagName tagName

  if window["define"]?
    define (require, exports, module) -> G
  else
    G.old = window.G if window.G?
    window.G = G

  slice = AP.slice
  toString = OP.toString
  hasOwn = OP.hasOwnProperty

  # [[[ utils
  G.extend = -> #form jquery 1.7.3 pre
    target = arguments[0] or {}
    length = arguments.length
    deep = false
    i = 1
    if @isBoolean target
      deep = target
      target = arguments[1]
      i = 2
    target = {} if typeof target isnt "object" and not @isFunction target
    [target, i] = [this, i - 1] if length is i
    for i in [i...arguments.length]
      if (options = arguments[i])?
        for name, copy of options
          src = target[name]
          continue if target is copy
          if deep and copy and (@isPlainObject(copy) or (copyIsArray = @isArray copy))
            if copyIsArray
              copyIsArray = false
              clone = src and if @isArray src then src else []
            else
              clone = src and if @isPlainObject src then src else {}
            target[name] = @extend deep, clone, copy
          else if copy isnt undefined
            target[name] = copy
    target
  # ]]]

  # [[[ type
  class2type = {} # 用于 G.toType 函数, 根据对象的 toString 输出得到对象的类型
  'Arguments Function Number String Date RegExp Array Boolean Object'.replace /[^, ]+/g, (typeName) ->
    class2type["[object #{typeName}]"] = typeName.toLowerCase()
    G["is#{typeName}"] = (obj) -> toString.call(obj) is "[object #{typeName}]"
  unless G.isArguments arguments
    G.isArguments = (obj) ->
      !!(obj and G.has obj, "callee")

  G.extend
    toType: (obj) -> unless obj? then String obj else class2type[toString.call obj] or "object"

    isWindow: (obj) -> obj? and obj is obj.window
    isNode: (obj) -> obj.nodeType?
    isElement: (obj) -> obj? and obj.nodeType is 1
    isFinite: (obj) -> @isNumber(obj) and isFinite obj
    isObject: (obj) -> obj is Object obj
    # isNaN 会隐式地把参数变为 Number 再判断
    isNaN: (obj) -> obj isnt obj
    isNull: (obj) -> obj is null
    isUndefined: (obj) -> obj is undefined
    isEmpty: (obj) ->
      return true unless obj?
      return obj.length is 0 if @isArray(obj) or @isString obj
      (return false if @has obj, key) for key of obj
      true
    isPlainObject: (obj) -> #from jquery 1.7.3 pre
      return false if !obj or @toType(obj) isnt "object" or obj.nodeType or @isWindow(obj)
      try
        return false if obj.constructor and !@has(obj, "constructor") and !@has(obj.constructor.prototype, "isPrototypeOf")
      catch e
        return false
      key for key of obj
      key is undefined or @has obj, key

  G.extend
    has: (obj, attr) -> hasOwn.call obj, attr
    toArray: (obj) -> #form underscore
      return [] unless obj?
      return slice.call obj if @isArray obj
      return slice.call obj if @isArguments obj
      return obj.toArray() if obj.toArray? and @isFunction obj.toArray
      v for k, v of obj
  # ]]]

  # [[[ number
  G.extend
    # TODO: 第三个参数，填充 0
    toFixed: (number, length=1) ->
      return if @isNaN (fnumber = parseFloat number)
      return number.toFixed length if number.toFixed?
      operator = 1
      operator *= 10 for i in [0..length]
      Math.round(fnumber * operator) / operator
  # ]]]

  # [[[ string
  G.extend
    stpl: (tpl, data) ->
      return unless tpl?
      return tpl unless data?
      return @stpl tpl["innerHtml"], data if @isElement tpl
      return data.map((partData) => @stpl tpl, partData).join "" if @isArray data
      tpl.replace /{{(.*?)}}/igm, ($, $1) -> `data[$1] ? data[$1] : $`

    reEscape: (str) ->
      str.replace(/\\/g, "\\\\")
        .replace(/\//g, "\\/").replace(/\,/g, "\\,").replace(/\./g, "\\.")
        .replace(/\^/g, "\\^").replace(/\$/g, "\\$").replace(/\|/g, "\\|")
        .replace(/\?/g, "\\?").replace(/\+/g, "\\+").replace(/\*/g, "\\*")
        .replace(/\[/g, "\\[").replace(/\]/g, "\\]")
        .replace(/\{/g, "\\{").replace(/\}/g, "\\}")
        .replace(/\(/g, "\\(").replace(/\)/g, "\\)")

    charUpperCase: (str, index=0, length=1) ->
      strList = str.split ''
      for i in [0...length]
        newIndex = index + i
        strList[newIndex] = strList[newIndex].toUpperCase()
      strList.join ''

    getDelta: (oldStr, newStr) ->
      resultList = []
      delta = ''
      delingIndex = 0
      contr = (oldStr, newStr, index) ->
        while newStr[index] isnt oldStr[index]
          delta += newStr[index]
          newStr = newStr.remove index
      deling = (oldStr, newStr, index) ->
        if newStr[index] not in oldStr
          oldStr = oldStr.remove(delingIndex)
          newStr = newStr.remove(index)
          deling index
      for i in newStr
        deling i if oldStr.length
      [oldStr, newStr]
  # ]]]

  # [[[ uri
  G.extend
    param: (obj) ->
      ("#{encodeURIComponent key}=#{encodeURIComponent JSON.stringify value}" \
        for key, value of obj).join "&"

    getParam: (url, key) ->
      key = @reEscape key
      re = new RegExp "\\??" + key + "=([^&]*)", "g"
      result = re.exec url
      if result? and result.length > 1
        decodeURIComponent result[1]
      else
        ""

    parseQueryParam: (queryStr) ->
      param = {}
      querystring_parser = /(?:^|&|;)([^&=;]*)=?([^&;]*)/g
      (queryStr or window.location.search)
        .replace(/^\?/, "")
        .replace querystring_parser, ($0, $1, $2) ->
          param[$1] = decodeURIComponent $2 if $1
      param
  # ]]]

  # [[[ stylesheets
  indexOf = AP.indexOf
  classRe = (className) ->
    new RegExp "(\\s+#{className}|\\s+#{className}\\s+|#{className}\\s+)", "g"

  G.extend
    addClass: (elem, className) ->
      elemClass = "#{elem.getAttribute("class") or ""} "
      unless elemClass.match(classRe(className))?
        elem.setAttribute "class", elemClass + className
      this

    removeClass: (elem, className) ->
      elemClass = elem.getAttribute("class") or ""
      elem.setAttribute "class", elemClass.replace classRe(className), ""
      this

    getCSS : (elem, styleName) ->
      elemStyle = if document.defaultView? \
        then document.defaultView.getComputedStyle elem \
        else elem.currentStyle
      unless styleName? then elemStyle else \
        if styleName isnt "float" then elemStyle[styleName] \
          else elemStyle["cssFloat"] or elemStyle["styleFloat"]
      this

    setCSS: (elem, styleName, styleValue) ->
      elemStyle = elem.style
      # TODO: 在 IE6 IE8 中测试
      elemStyle.cssText = elemStyle.cssText.replace new RegExp("#{styleName}\s:.*;+\s", "g"), ""
      elemStyle.cssText += "#{styleName}: #{styleValue};"
      this
  # ]]]

) window, document
