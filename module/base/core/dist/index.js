// Generated by LiveScript 1.6.0
(function(){
  var servebase;
  ldc.register('core', [], function(){
    return {
      init: proxise.once(function(){
        var err, this$ = this;
        this.global = {};
        this.user = {};
        this.zmgr = new zmgr();
        this.manager = new block.manager({
          registry: function(arg$){
            var name, version, path, type;
            name = arg$.name, version = arg$.version, path = arg$.path, type = arg$.type;
            path = path || (type === 'block'
              ? 'index.html'
              : type ? "index.min." + type : 'index.min.js');
            if (/^@local\/(error|cover|block)/.exec(name)) {
              return "/modules/" + name.replace(/^@local\//, '') + "/" + (path || 'index.html');
            }
            return "/assets/lib/" + name + "/" + (version || 'main') + "/" + path;
          }
        });
        this.loader = new ldloader({
          className: "ldld full",
          autoZ: true,
          baseZ: null,
          zmgr: this.zmgr.scope(zmgr.splash)
        });
        this.captcha = new captcha({
          manager: this.manager,
          zmgr: this.zmgr.scope(zmgr.splash)
        });
        this.ldcvmgr = new ldcvmgr({
          manager: this.manager,
          errorCover: {
            name: "@local/error",
            path: "0.html"
          }
        });
        this.i18n = i18next;
        this.auth = new auth({
          manager: this.manager,
          zmgr: this.zmgr,
          loader: this.loader
        });
        ldc.action('ldcvmgr', this.ldcvmgr);
        err = new lderror.handler({
          handler: function(n, e){
            return this$.ldcvmgr.get({
              name: "@local/error",
              path: n + ".html"
            }, e);
          }
        });
        this.error = function(e){
          return err(e);
        };
        this.update = function(g){
          return this.global = g, this.user = g.user || {}, this;
        };
        this.auth.on('server-down', this.error);
        this.auth.on('logout', function(){
          return window.location.replace('/');
        });
        return this.manager.init().then(function(){
          if (typeof i18next == 'undefined' || i18next === null) {
            return;
          }
          return Promise.resolve().then(function(){
            return i18next.init({
              supportedLng: ['en', 'zh-TW'],
              fallbackLng: 'zh-TW',
              fallbackNS: '',
              defaultNS: ''
            });
          }).then(function(){
            if (typeof i18nextBrowserLanguageDetector != 'undefined' && i18nextBrowserLanguageDetector !== null) {
              return i18next.use(i18nextBrowserLanguageDetector);
            }
          }).then(function(){
            var lng;
            lng = (typeof httputil != 'undefined' && httputil !== null ? httputil.qs('lng') || httputil.cookie('lng') : null) || navigator.language || navigator.userLanguage;
            console.log("use language: ", lng);
            return i18next.changeLanguage(lng);
          }).then(function(){
            return block.i18n.use(i18next);
          });
        }).then(function(){
          return this$.auth.get();
        }).then(function(g){
          this$.global = g;
          this$.user = g.user;
          return this$.captcha.init(g.captcha);
        }).then(function(){
          this$.auth.on('change', function(g){
            return this$.update(g);
          });
          return this$;
        });
      })
    };
  });
  servebase = {
    corectx: function(cb){
      return new Promise(function(res, rej){
        var ret;
        ret = ldc.register(['core'], function(o){
          return o.core.init().then(function(){
            return cb.apply(o.core, [o]);
          }).then(res)['catch'](rej);
        });
        return ldc.init(ret);
      });
    }
  };
  if (typeof module != 'undefined' && module !== null) {
    module.exports = servebase;
  } else if (typeof window != 'undefined' && window !== null) {
    window.servebase = servebase;
  }
}).call(this);
