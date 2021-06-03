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
