svgns = "http://www.w3.org/2000/svg"

layout = (opt={}) ->
  @root = if typeof(opt.root) == \string => document.querySelector(opt.root) else opt.root
  @opt = {auto-svg: true} <<< opt
  if !(@opt.watch-resize?) => @opt.watch-resize = true
  @evt-handler = {}
  @box = {}
  @node = {}
  @group = {}
  @

resizeObserver = do
  wm: new WeakMap!
  ro: new ResizeObserver (list) ->
    list.map (n) ->
      ret = resizeObserver.wm.get(n.target)
      ret.update!
  add: (node, obj) ->
    @wm.set node, obj
    @ro.observe node
  delete: ->
    @ro.unobserve it
    @wm.delete it

layout.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> @evt-handler.[][n].push cb
  fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
  init: (cb) ->
    <~ Promise.resolve!then _
    if @opt.watch-resize => resizeObserver.add @root, @
    if (!(@opt.auto-svg?) or @opt.auto-svg) =>
      svg = @root.querySelector('[data-type=render] > svg')
      if !svg =>
        svg = document.createElementNS(svgns, "svg")
        svg.setAttribute \width, \100%
        svg.setAttribute \height, \100%
        @root.querySelector('[data-type=render]').appendChild svg
      Array.from(@root.querySelectorAll('[data-type=layout] .pdl-cell[data-name]')).map (node,i) ~>
        name = node.getAttribute \data-name
        @node[name] = node
        if node.hasAttribute \data-only => return
        g = @root.querySelector("g.pdl-cell[data-name=#{name}]")
        if !g =>
          g = document.createElementNS(svgns, "g")
          svg.appendChild g
          g.classList.add \pdl-cell
          g.setAttribute \data-name, name
        @group[name] = g

    ret = cb.apply @
    if ret and typeof(ret.then) == \function => ret.then(~>@update!) else @update!
  destroy: -> resizeObserver.delete @root
  # opt: fire rendering event if opt is true or undefined.
  update: (opt) ->
    if !@root => return
    if !(opt?) or opt => @fire \update
    @rbox = @root.getBoundingClientRect!
    Array.from(@root.querySelectorAll('[data-type=layout] .pdl-cell[data-name]')).map (node,i) ~>
      name = node.getAttribute \data-name
      @node[name] = node
      @box[name] = box = node.getBoundingClientRect!{x,y,width,height}
      box.x -= @rbox.x
      box.y -= @rbox.y
      if node.hasAttribute \data-only => return
      @group[name] = g = @root.querySelector("g.pdl-cell[data-name=#{name}]")
      g.setAttribute \transform, "translate(#{box.x},#{box.y})"
      g.layout = {node, box}
    if !(opt?) or opt => @fire \render
  get-box: ->
    # from cached value:
    #return @box[it]
    # or realtime value:
    rbox = @root.getBoundingClientRect!
    box = @get-node(it).getBoundingClientRect!
    box.x -= rbox.x
    box.y -= rbox.y
    return box
  get-node: -> @node[it]
  get-group: -> @group[it]

if window? => window.layout = layout
if module? => module.exports = layout
