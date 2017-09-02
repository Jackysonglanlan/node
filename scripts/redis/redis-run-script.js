// 

'use strict';

require('yqj-commons');

const redis = yqj_require('src/db/DB').redis;

//////////// CMD definition ////////////

/**
 * @type {Object} cmd -> cmdLineDesc
 */
const AvaiableCMDList = {};

function defineCommand(cmd, cmdLineDesc, configBlock) {
  AvaiableCMDList[cmd] = cmdLineDesc;
  redis.defineCommand(cmd, configBlock);
}

defineCommand('clean', 'clean redis db, usage: --cmd=clean(KEY_PATTEN)', {
  numberOfKeys: 0,
  lua: 'return redis.call(\'del\', unpack(redis.call(\'keys\', ARGV[1])))'
});

// TODO: add more cmd when needed...



//////////// run ////////////

if (process.argv.length !== 3) {
  console.log('pass "--cmd=CMD" to use the script.');
  console.log('Avaiable cmds:\n  %s', Object.keys(AvaiableCMDList).map((key) => {
    return `${key}: ${AvaiableCMDList[key]}`;
  }).join('\n  '));

  process.reallyExit();
}

var cmdArea = process.argv[2].split('=');

if (cmdArea[0] !== '--cmd') {
  console.log('pass "--cmd=CMD arg1 arg2 ... argN" to use the script.');
  process.reallyExit();
}

// invokeLine is like 'taskName(arg1, arg2, ...)'
function runScript(invokeLine) {
  const cmd = invokeLine.split(/\(|,|\)/);
  return redis[cmd.shift()].apply(redis, cmd);
}

runScript(cmdArea[1]).then((result) => {
  log(`Success! Finish executing '${cmdArea[1]}' and return: ${result}`);
}).catch((err) => {
  log(err);
}).then(() => {
  process.reallyExit();
});









//
