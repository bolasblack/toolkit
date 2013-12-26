((definition) ->
  # requirejs
  if typeof define is "function" and define.amd
    define ["toolkit"], (G) -> definition G
  # CMD and CommandJS
  else if exports?
    G = require "./toolkit"
    if module? and module.exports
      module.exports = definition G
    else
      exports.G = definition G
  # normal
  else
    definition @G
) (G) ->
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
      return @stpl tpl.innerHtml, data if @isElement tpl
      return (@stpl(tpl, partData) for partData in data).join "" if @isArray data
      tpl.replace /{{(.*?)}}/igm, ($, $1) -> if data[$1]? then data[$1] else $

    #
    # Escape/Unescape HTML entities in Javascript
    # http://www.w3.org/TR/html4/sgml/entities.html
    #
    # The professional solution: http://www.strictly-software.com/htmlencode
    #
    # thx http://stackoverflow.com/a/1912522
    #
    htmlEncode: (string) ->
      elem = document.createElement "div"
      elem.innerText = string
      if elem.childNodes.length is 0 then "" else elem.innerHTML

    htmlDecode: (string) ->
      elem = document.createElement "div"
      elem.innerHTML = string
      if elem.childNodes.length is 0 then "" else elem.innerText

    reEscape: (str, skipChar=[]) ->
      reSpecialChar = [
        "\\", "/", ",", "."
        "|", "^", "$", "?"
        "+", "*", "[", "]"
        "{", "}", "(", ")"
      ]
      for char in reSpecialChar when char not in skipChar
        re = RegExp "\\" + char, "g"
        str = str.replace re, "\\#{char}"
      str

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
      re = ///\??#{key}=([^&]*)///g
      result = re.exec url
      if result? and result.length > 1
        decodeURIComponent result[1]
      else
        ""

    parseQueryParam: (queryStr=window.location.search) ->
      param = {}
      querystring_parser = /(?:^|&)([^&=]*)=?([^&]*)/g
      queryStr.replace(/^\?/, "")
        .replace querystring_parser, ($0, $1, $2) ->
          param[$1] = decodeURIComponent $2 if $1
      param
  # ]]]

  # [[[ stylesheets
  indexOf = Array::indexOf
  classRe = (className) ->
    className = G.reEscape className
    ///(\s+#{className}|\s+#{className}\s+|#{className}\s+)///g

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
      # 在 < ie9 中，css 属性名会大写
      elemStyle.cssText = elemStyle.cssText.replace new RegExp("#{styleName}\s:.*;+\s", "gi"), ""
      # 在 < ie9 中行末的 css 会被删除分号
      elemStyle.cssText = elemStyle.cssText.replace /;?$/, ";#{styleName}: #{styleValue}"
      this
  # ]]]

