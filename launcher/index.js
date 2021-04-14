#!/usr/bin/env node osascript -l JavaScript

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title workflow-launcher
// @raycast.mode fullOutput
// @raycast.packageName Raycast Scripts
//
// Optional parameters:
// @raycast.icon ⚡️
// @raycast.argument1 { "type": "text", "placeholder": "js, css, html", "optional": false}
// @raycast.argument2 { "type": "text", "placeholder": "query" }
// @raycast.argument3 { "type": "text", "placeholder": "query" }
// @raycast.argument4 { "type": "text", "placeholder": "query" }
//
// Documentation:
// @raycast.description Write a nice and descriptive summary about your script command here
// @raycast.author CxGarcia
// @raycast.authorURL https://github.com/cxgarcia/

const { exec, execSync, spawnSync } = require('child_process');
const path = require('path');

let [project] = process.argv;

const { readdir } = require('fs/promises');

const HOME = require('os').homedir();
const PROJECT_PATH = `${HOME}/Documents/code/hogwarts`;

// exec('open -a iTerm', (error, stdout, stderr) => {
//   console.log(stdout);
//   console.log(stderr);
//   if (error !== null) {
//     console.log(`exec error: ${error}`);
//   }
// });

//Open VS Code
exec(`cd ${PROJECT_PATH} && git pull && code .`, (error, stdout, stderr) => {
  console.log(stdout);
  console.log(stderr);
  if (error !== null) {
    console.log(`exec error: ${error}`);
  }
});

async function getProjects() {
  const folders = await readdir(PROJECT_PATH);
  return folders;
}
