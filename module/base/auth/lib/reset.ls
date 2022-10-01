require! <[crypto lderror]>
require! <[@servebase/backend/throttle @servebase/backend/aux]>

(backend) <- ((f) -> module.exports = -> f it) _
{db,config,route} = backend
mdw = throttle: throttle.kit.login, captcha: backend.middleware.captcha

route.auth.post \/passwd/reset/:token, mdw.throttle, mdw.captcha, (req, res) ->
  token = req.params.token
  password = {plain: req.body.password}
  db.user-store.hashing password.plain, true, true
    .then (ret) ->
      password.hashed = ret
      db.query(["select users.key from users,pwresettoken"
      "where pwresettoken.token=$1 and users.key=pwresettoken.owner"].join(" "),[token])
    .then (r={}) ->
      if !r.[]rows.length => return lderror.reject 403
      user = r.rows.0
      user.password = password.hashed
      db.query "update users set (password,method) = ($2,$3) where key = $1", [user.key, user.password, \local]
    .then -> db.query "delete from pwresettoken where pwresettoken.token=$1", [token]
    .then -> res.send!

route.app.get \/auth/passwd/reset/:token, mdw.throttle, (req, res) ->
  token = req.params.token
  if !token => return lderror.reject 400
  db.query "select owner,time from pwresettoken where token = $1", [token]
    .then (r={})->
      if !r.[]rows.length => return lderror.reject 403
      obj = r.rows.0
      if new Date!getTime! - new Date(obj.time).getTime! > 1000 * 600 =>
        return res.redirect \/auth/passwd/reset/expire/
      res.cookie "password-reset-token", token
      res.redirect "/auth/passwd/reset/change/"

route.auth.post \/passwd/reset, mdw.throttle, mdw.captcha, (req, res) ->
  email = "#{req.body.email}".trim!
  if !email => return lderror.reject 400
  obj = {}
  db.query "select key from users where username = $1", [email]
    .then (r={}) ->
      if r.[]rows.length == 0 => return lderror.reject 404
      time = new Date!
      obj <<< {key: r.rows.0.key, hex: "#{r.rows.0.key}" + (crypto.randomBytes(30).toString \hex), time: time }
      db.query "delete from pwresettoken where owner=$1", [obj.key]
    .then -> db.query "insert into pwresettoken (owner,token,time) values ($1,$2,$3)", [obj.key, obj.hex, obj.time]
    .then ->
      backend.mail-queue.by-template(
        \reset-password
        email
        {token: obj.hex}
        {now: true}
      )
    .then -> res.send ''

route.auth.put \/passwd/, mdw.throttle, aux.signedin, (req, res, next) ->
  {n,o} = req.body{n,o}
  Promise.resolve!
    .then ->
      {n,o} = req.body{n,o}
      if !req.user => return aux.reject 403
      if n.length < 8 => return aux.reject 1031
      db.query "select password from users where key = $1", [req.user.key]
    .then (r = {}) ->
      if !(u = r.[]rows.0) => return aux.reject 403
      db.user-store.compare o, u.password
        .catch -> return aux.reject 1030
    .then -> db.user-store.hashing n
    .then (password) ->
      req.user <<< {password}
      db.query "update users set (password,method) = ($1,'local') where key = $2", [password, req.user.key]
    .then -> new Promise (res, rej) -> req.login(req.user, -> res!)
    .then -> res.send!

