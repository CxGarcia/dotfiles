#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const args = process.argv.slice(2);
const cwd = process.cwd();

//filter out flags from args array
const filteredArgs = args.filter((arg) => !arg.startsWith('-'));

const cmdPath = path.join(__dirname, 'scripts', args[0]);

if (fs.existsSync(cmdPath)) {
  // console.log('hiya');
  const cxSpawn = exec(path.join(cmdPath, 'index.js'), args.slice(1));

  cxSpawn.stdout.on('data', (data) => {
    console.log(data);
  });

  cxSpawn.stderr.on('data', (data) => {
    console.error(`error: ${data}`);
  });
}
