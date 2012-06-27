((undefined) ->
  return unless G.isNaN?
  supportType = "string array object".split " "

  defaultDefineConfig =
    in: window #TODO: 了解 node 环境里的 global 叫什么

  def = (obj, inputDefineConfig) ->
    objType = G.toType obj
    return obj unless objType in supportType
    obj.defed = -> true

  def.extra = (extraConfig) ->
)()
