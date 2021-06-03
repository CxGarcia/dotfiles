#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const yargs = require('yargs/yargs');
const { exec } = require('child_process');
const { hideBin } = require('yargs/helpers');

const argv = yargs(hideBin(process.argv)).argv;
const cmdPath = path.join(__dirname, 'scripts', argv['_'][0]);

if (fs.existsSync(cmdPath)) {
  const cmd = exec(
    `${path.join(cmdPath, 'index.js')} ${args.slice(1).join(' ')}`
  );

  cmd.stdout.on('error', (err) => {
    if (err) throw err;
  });

  cmd.stdout.on('data', (data) => {
    console.log(data);
  });

  cmd.stderr.on('data', (data) => {
    console.error(`error: ${data}`);
  });
} else console.log('cmd does not exists');
