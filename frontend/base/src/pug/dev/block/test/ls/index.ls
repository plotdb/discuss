module.exports =
  init: ->
    ldc.register <[core]>, ({core}) ->
      <- core.init!then _
      {auth, manager} = core
      Promise.resolve!
        .then ->
          # if we have user.key, user may have already logged in. try to re-fetch user info
          if !core.user.key => Promise.resolve!
          auth.fetch {renew: true}
            .then (g) ->
              if !(g.user and g.user.key) => return
              <- new Promise _ # never resolve
              # user is indeed logged in. simply redirect to landing page
              window.location.replace '/'
        .then ->
          # oherwise trigger login panel
          manager.from {name: "@servebase/auth"}, {root: document.body, data: {auth}}
        .then (o) -> o.interface true, {lock: true}
        # user will be here only if they login in this page.
        # however, this may be redirected by middlewares such as `signedin` -
        # in this case URL will still be the URL guarded by `signedin`. so we simply reload
        # even it's still `/auth/`, user will still be redirect to `/` by above code.
        # TODO: we can design to use cookie as nexturl information.
        # it may be a Nginx `X-Accel-Redirect` so we simply reload URL.
        .then ->
          if window.location.pathname == "/auth/" => window.location.replace '/'
          else window.location.reload!
    ldc.init!
