({core}) <- servebase.corectx _

ctx = {}
view = new ldview do
  init-render: false
  root: document.body
  action: click: post: ->
    comment = view.get('edit')
    core.captcha.guard cb: (captcha) ->
      payload = {captcha, content: {body: comment.value or ''}, uri: \/}
      core.loader.on!
      ld$.fetch \/api/discuss, {method: \POST}, {json: payload, type: \json}
        .finally -> core.loader.off!
        .then ->
    
  handler:
    comment:
      list: -> ctx.comments or []
      key: -> it.key
      view:
        handler: "content": ({node, ctx}) -> node.innerText = ((ctx.content or {}).body or '')

core.loader.on!
ld$.fetch "/api/discuss?uri=/", {method: \GET}, {type: \json}
  .finally -> core.loader.off!
  .then (ret) ->
    ctx <<< ret
    console.log ret
    view.render!
