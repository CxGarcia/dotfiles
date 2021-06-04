#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const args = process.argv.slice(2);
const cmdPath = path.join(__dirname, 'scripts', args[0]);

if (fs.existsSync(cmdPath)) {
  const child = exec(
    `${path.join(cmdPath, 'index.js')} ${args.slice(1).join(' ')}`
  );

  child.stdout.on('data', (data) => {
    console.log(data);
  });

  child.stderr.on('data', (data) => {
    console.error(`error: ${data}`);
  });
}
