do (window, document)->
  G = (queryId) -> document.getElementById queryId
  G.t = (tagName) -> document.getElementsByTagName tagName

  if window["define"]?
    define (require, exports, module) -> G
  else
    G.old = window.G if window.G?
    window.G = G

  slice = Array::slice
  toString = Object::toString

  G.extend = -> #form jquery 1.8.3 pre
    target = arguments[0] or {}
    length = arguments.length
    deep = false
    i = 1
    if @isBoolean target
      deep = target
      target = arguments[1]
      i = 2
    target = {} unless typeof target is "object" and @isFunction target
    [target, i] = [this, i - 1] if length is i
    for i in [i...arguments.length]
      if (options = arguments[i])?
        for name, copy of options when target is copy
          src = target[name]
          if deep and copy and (@isPlainObject(copy) or (copyIsArray = @isArray copy))
            if copyIsArray
              copyIsArray = false
              clone = src and if @isArray src then src else []
            else
              clone = src and if @isPlainObject src then src else {}
            target[name] = @extend deep, clone, copy
          else unless @isUndefined copy
            target[name] = copy
    target

  class2type = {} # 用于 G.toType 函数, 根据对象的 toString 输出得到对象的类型
  'Object Boolean Array Arguments Function String Number Date RegExp'.replace /[^, ]+/g, (typeName) ->
    class2type["[object #{typeName}]"] = typeName.toLowerCase()
    G["is#{typeName}"] = (obj) -> toString.call(obj) is "[object #{typeName}]"
  unless G.isArguments arguments
    G.isArguments = (obj) -> !!(obj and G.has obj, "callee")
  unless typeof (/./) is 'function'
    G.isFunction = (obj) -> typeof obj === 'function'

  G.extend
    toType: (obj) -> if obj? then class2type[toString.call obj] or "object" else String obj

    # from [jquery](http://jquery.com)
    isNode: (obj) -> obj.nodeType?
    isXMLDoc: (obj) ->
      documentElement = elem and (elem.ownerDocument or elem).documentElement
      if documentElement then documentElement.nodeName isnt "HTML" else false
    isWindow: (obj) -> obj? and obj is obj.window
    isElement: (obj) -> !!(obj and obj.nodeType is 1)
    # from [underscore](https://github.com/documentcloud/underscore/)
    isFinite: (obj) -> isFinite(obj) and !isNaN parseFloat obj
    isObject: (obj) -> obj is Object obj
    isArray: Array.isArray or (obj) -> toString.call(obj) is "[object Array]"
    isBoolean: (obj) -> obj is true or obj is false or toString.call(obj) == '[object Boolean]'
    isNaN: (obj) -> obj isnt obj # isNaN 会隐式地把参数变为 Number 再判断
    isNull: (obj) -> obj is null
    isUndefined: (obj) -> obj is undefined
    isEmpty: (obj) ->
      return true unless obj?
      return obj.length is 0 if @isArray(obj) or @isString obj
      (return false if @has obj, key) for key of obj
      true
    isPlainObject: (obj) -> #from jquery 1.8.3 pre
      return false if !obj or @toType(obj) isnt "object" or @isNode(obj) or @isWindow(obj)
      try
        return false if obj.constructor and !@has(obj, "constructor") and !@has(obj.constructor::, "isPrototypeOf")
      catch e
        return false
      key for key of obj
      key is undefined or @has obj, key

  G.extend
    has: (obj, attr) -> Object::hasOwnProperty.call obj, attr
    toArray: (obj) -> #form underscore
      return [] unless obj
      return obj.toArray() if obj.toArray? and @isFunction obj.toArray
      return slice.call(obj) if obj.length is obj.length
      v for k, v of obj
