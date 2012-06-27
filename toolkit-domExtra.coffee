((window, G) ->
  Events = ( ->
    Events = {}

    get = (elem, eventName) ->
      return G.extend {}, Events unless elem?
      return G.extend {}, Events[elem] unless eventName? and eventName isnt ""
      G.extend [], Events[elem]?["$#{eventName}"]

    reg = (elem, eventName, callback) ->
      Events[elem] or= {}
      Events[elem]["$#{eventName}"] or= []
      Events[elem]["$#{eventName}"].push callback

    return {get, reg}
  )()

  w3cHandleRunner = (e, handler) ->
    keepBubble = handler? e
    if keepBubble is false
      e.stopPropagation()
      e.preventDefault()
    keepBubble

  ieHandleRunner = (e, handler) ->
    keepBubble = handler? e
    if keepBubble is false
      window.event.cancelBubble = !keepBubble
      window.event.returnValue = keepBubble
    keepBubble

  G.extend
    addEvent: (elem, eventName, callback) ->
      Events.reg elem, eventName, callback
      if elem.addEventListener?
        elem.addEventListener eventName, (e) ->
          e.srcElement or= e.target
          for handler in EventList[elem][eventName]
            keepBubble = w3cHandleRunner e, handler
            break unless keepBubble
        , false
      else if elem.attachEvent?
        elem.attachEvent "on#{eventName}", ->
          e = G.extend {}, window.event # 防止全局污染
          e.target = e.srcElement
          for handler in EventList[elem][eventName]
            keepBubble = ieHandleRunner e, handler
            break unless keepBubble
      elem

    removeEvent: (elem, eventName, handler) ->
      if elem.removeEventListener?
        elem.removeEventListener eventName, handler
      else if elem.detachEvent?
        elem.detachEvent "on#{eventName}", handler
      elem
    
    listEvent: Events.get
) window, window.G
