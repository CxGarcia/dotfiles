#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const text = require('./text');

const args = process.argv.slice(2);

for (const arg of args) {
  const cxScriptsDir = path.join(__dirname, '..');
  const cmdDir = path.join(cxScriptsDir, arg);
  const scriptFile = path.join(cmdDir, 'index.js');

  //skip dir creation if it already exists
  if (fs.existsSync(cmdDir)) {
    console.log(
      `${cmdDir} already exists at: ${cmdDir} - will skip its creation until the directory is deleted`
    );

    continue;
  }

  fs.mkdirSync(cmdDir);

  fs.appendFile(scriptFile, text['index'].trim(), function (err) {
    if (err) throw err;
  });
}

// {
//   mode: 0o755;
// }

//path to script /System/Volumes/Data/Users/cristobalschlaubitz/.fnm/node-versions/v16.1.0/installation/bin

// const packageJson = await fs.readFile(path.join(__dirname, ))

async function findPkgJson(basePath = __dirname) {
  const pkgPath = path.join(basePath, 'package.json');

  if (!fs.existsSync(pkgPath)) {
    return findPkgJson(path.join(basePath, '..'));
  }

  const pkg = await fs.promises.readFile(pkgPath);

  return JSON.parse(pkg);
}
