'use strict';

/**
 * Usage:
 *
 * NODE_ENV=dev node scripts/mongodb/mongodb-drop-db.js
 */

require('yqj-commons');

const mongo = yqj_require('src/db/DB').mongo;

log(`Start droping mongodb '${mongo.config.db}'`);

mongo.get().dropDatabase().then(() => {
  log(`Finished, mongodb '${mongo.config.db}' is droped...`);
  process.exit(0);
});
