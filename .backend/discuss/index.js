// Generated by LiveScript 1.6.0
(function(){
  var fs, path, lderror;
  fs = require('fs');
  path = require('path');
  lderror = require('lderror');
  (function(it){
    return module.exports = it;
  })(function(backend){
    return function(it){
      return it.apply(backend);
    }(function(){
      var db, config, ref$, api, app, session;
      db = this.db, config = this.config, ref$ = this.route, api = ref$.api, app = ref$.app, session = this.session;
      return fs.readdirSync(__dirname).filter(function(it){
        return !/^index\./.exec(it);
      }).filter(function(it){
        return !/^\./.exec(it);
      }).map(function(it){
        return path.join(__dirname, it);
      }).filter(function(it){
        return /\.(ls|js)$/.exec(it) || fs.statSync(it).isDirectory();
      }).map(function(it){
        return require(it)(backend);
      });
    });
  });
}).call(this);
