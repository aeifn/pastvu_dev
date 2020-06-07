module.exports = function (config, appRequire) {
    const _ = appRequire('lodash');

    _.merge(config, {
        client: {
            hostname: '127.0.0.1 localhost mypastvu.com',
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
