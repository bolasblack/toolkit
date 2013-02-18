do ->
  G = (queryId) -> document.getElementById queryId

  # requirejs
  if typeof define is "function" and define.amd
    define -> G
  # CMD and CommandJS
  else if exports?
    if module? and module.exports
      module.exports = G
    else
      exports.G = G
  # normal
  else
    G.old = @G if @G?
    @G = G

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
        for name, copy of options when target isnt copy
          src = target[name]
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

  class2type = {} # 用于`G.toType`函数，根据对象的`toString`方法输出得到对象的类型
  types = 'Boolean Arguments Function String Number Date RegExp'
  types.replace /[^, ]+/g, (typeName) ->
    class2type["[object #{typeName}]"] = typeName.toLowerCase()
    G["is#{typeName}"] = (obj) -> toString.call(obj) is "[object #{typeName}]"
  unless G.isArguments arguments
    G.isArguments = (obj) -> !!(obj and G.has obj, "callee")
  unless typeof (/./) is 'function'
    G.isFunction = (obj) -> typeof obj is 'function'

  G.extend
    has: (obj, attr) -> Object::hasOwnProperty.call obj, attr
    toType: (obj) -> if obj? then class2type[toString.call obj] or "object" else String obj
    toArray: (obj) -> # form underscore
      return [] unless obj
      return obj.toArray() if obj.toArray? and @isFunction obj.toArray
      return slice.call(obj) if obj.length is obj.length
      v for k, v of obj

  G.extend
    # from [jquery](http://jquery.com)
    isNode: (obj) -> obj.nodeType?
    isXMLDoc: (obj) ->
      documentElement = obj and (obj.ownerDocument or obj).documentElement
      if documentElement then documentElement.nodeName isnt "HTML" else false
    isWindow: (obj) -> obj? and obj is obj.window
    isElement: (obj) -> !!(obj and obj.nodeType is 1)

    isEmptyObject: (obj) ->
      return false for key of obj
      true

    isPlainObject: (obj) ->
      # Must be an Object.
      # Because of IE, we also have to check the presence of the constructor property.
      # Make sure that DOM nodes and window objects don't pass through, as well
      return false if !obj \
        or @toType(obj) isnt "object" \
        or @isNode(obj) \
        or @isWindow(obj)

      try
        # Not own constructor property must be Object
        return false if obj.constructor \
          and !@has(obj, "constructor") \
          and !@has(obj.constructor::, "isPrototypeOf")
      catch e
        # IE8,9 Will throw exceptions on certain host objects #9897
        return false

      key for key of obj
      key is undefined or @has obj, key

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
      @isEmptyObject obj
