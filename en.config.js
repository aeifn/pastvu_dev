module.exports = function(config, appRequire) {
  const _ = appRequire('lodash');

  _.merge(config, {

    listen: {
      // Accept only this host. If the hostname is omitted,
      // the server will accept connections directed to any IPv4 address (INADDR_ANY)
      hostname: '',
      port: 3000, // Application app.js will listen this port
      uport: 3001, // Application uploader.js will listen this port
      dport: 3002, // Application downloader.js will listen this port
    },

    client: {
      hostname: '185.197.73.34',
    },

    core: {
      hostname: 'app',
      port: 3010,
    },

    api: {
      hostname: 'app',
      port: 3011,
    },

    storePath: '/store',
    logPath: '/logs',

    mongo: {
      connection: 'mongodb://mongo:27017/pastvu',
    },
    mongo_api: {
      con: 'mongodb://mongo:27017/pastvu',
    },
    redis: {
      host: 'redis',
    },

    // In development you should create a test account at https://ethereal.email, so email will not be sent to the real users
    mail: {
      type: 'SMTP',
      secure: true,
      host: '',
      port: 0,
      auth: {
        user: '',
        pass: '',
      },
    },
  });

  return config;
};
