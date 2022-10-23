require! <[fs path lderror @plotdb/suuid @grantdash/dashlib]>
require! <[@servebase/backend/throttle @servebase/backend/aux]>

(backend) <- (->module.exports = it)  _
<-(->it.apply backend) _

lib = dashlib backend

{db,config,route:{api,app},session} = @

all-thread = (req, res) ->
  limit = if isNaN(req.query.limit) => 20 else +req.query.limit <? 100
  offset = if isNaN(req.query.offset) => 0 else +req.query.offset
  db.query """
  select d.title, d.slug, d.createdtime, d.modifiedtime, json_agg(distinct c.owner) as users
  from discuss as d
  left join comment as c on d.key = c.discuss
  group by d.key
  limit $1 offset $2
  """, [limit, offset]
    .then (r={}) -> res.send r.[]rows
    .catch aux.error-handler res

api.get \/discuss/, (req, res) ->
  lc = {}
  {slug,uri} = req.query{slug, uri}
  if !(slug or uri) => return all-thread req, res
  limit = if isNaN(req.query.limit) => 20 else +req.query.limit <? 100
  offset = if isNaN(req.query.offset) => 0 else +req.query.offset
  promise = if slug => db.query "select key,title from discuss where slug = $1 limit 1", [slug]
  else db.query "select key,title from discuss where uri = $1 limit 1", [uri]
  promise
    .then (r={}) ->
      lc.discuss = discuss = r.[]rows.0
      if !discuss => return res.send({})
      db.query """
      select c.*, u.displayname
      from comment as c, users as u
      where c.discuss = $1 and c.owner = u.key
      and c.deleted is not true
      and c.state = 'active'
      order by distance limit $2 offset $3
      """, [discuss.key, limit, offset]
        .then (r= {}) ->
          res.send( {discuss: lc.discuss, comments: r.[]rows} )

api.post \/discuss/, aux.signedin, throttle.kit.generic, backend.middleware.captcha, (req, res) ->
  lc = {}
  Promise.resolve!
    .then ->
      if !req.body => return lderror.reject 400
      lc <<< req.body{uri, slug, reply, content, title}
      lc.content = (lc.content or {}){body, config}
      if lc.slug => db.query "select key, slug from discuss where slug = $1", [lc.slug]
      else if lc.uri => db.query "select key, slug from discuss where uri = $1", [lc.uri]
      else return {}
    .then (r = {}) ->
      if r.[]rows.length => return Promise.resolve(r)
      # new discuss. Since it's new, user should not know its slug.
      lc.slug = suuid!
      db.query """
      insert into discuss (slug, uri, title) values ($1,$2,$3) returning key
      """, [lc.slug, lc.uri, (lc.title or '')]
    .then (r={}) ->
      lc.discuss = (r.[]rows.0 or {})
      if !lc.discuss.key => return aux.reject 400
      if !lc.discuss.slug => lc.discuss.slug = lc.slug
      return if lc.reply =>
        db.query """
        select c.* from comment as c
        where key = $1 and c.deleted is not true and c.state = 'active'
        """, [lc.reply]
      else
        db.query """
        select count(c.key) as distance, d.key as discuss
        from comment as c, discuss as d 
        where c.reply is null and d.key = $1 and d.key = c.discuss
        group by d.key
        """, [lc.discuss.key]
    .then (r={}) ->
      ret = (r.[]rows.0 or {})
      distance = (if isNaN(+ret.distance) => 0 else +ret.distance)
      lc <<< distance: (distance + 1), state: \active
      db.query """
      insert into comment
      (owner,discuss,distance,content,state,reply) values ($1,$2,$3,$4,$5,$6)
      returning key
      """, [req.user.key, lc.discuss.key, lc.distance, lc.content, lc.state, lc.reply]
    .then (r={}) ->
      lc.ret = r.[]rows.0 or {}
      lc.ret <<< {slug: lc.discuss.slug}
      db.query "update discuss set modifiedtime = now()"
    .then -> res.send lc.ret

/*
api.put \/discuss, (req, res) ->
  if !req.user => return aux.r404 res
  lc = {}
  Promise.resolve!
    .then ->
      lc.content = req.body.content{body, config}
      db.query "update comment set (content) = ($1)", [lc.content]
    .then -> res.send!
    .catch aux.error-handler res

api.delete \/discuss/:id, (req, res) ->
  if !req.user => return aux.r404 res
  if isNaN(key = +req.params.id) => return aux.r404 res
  db.query "update comment set deleted = true where key = $1 and owner = $2", [key, req.user.key]
    .then -> res.send!
    .catch aux.error-handler res
*/
