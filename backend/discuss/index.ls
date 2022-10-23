require! <[fs path lderror]>
(backend) <- (->module.exports = it)  _
<-(->it.apply backend) _

{db,config,route:{api,app},session} = @

fs.readdir-sync __dirname
  .filter -> !/^index\./.exec(it)
  .filter -> !/^\./.exec(it)
  .map -> path.join(__dirname, it)
  .filter -> /\.(ls|js)$/.exec(it) or fs.stat-sync(it).is-directory!
  .map -> require(it) backend

