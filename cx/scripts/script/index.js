#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const yargs = require('yargs/yargs');
const { exec } = require('child_process');
const { hideBin } = require('yargs/helpers');

const argv = yargs(hideBin(process.argv)).option('cmd', {
  alias: 'c',
  type: 'boolean',
  description: 'add its own command in the cli',
}).argv;

console.log(argv);

for (const cmd of argv['_']) {
  const scriptsDir = path.join(__dirname, '..');
  const dirPath = path.join(scriptsDir, cmd);

  //skip dir creation if it already exists
  if (fs.existsSync(dirPath)) {
    console.log(
      `${dirPath} already exists at: ${dirPath} - will skip its creation until the directory is deleted`
    );

    continue;
  }

  fs.mkdirSync(dirPath);

  //create files module
  const files = filesModule(dirPath);
  const keys = Object.keys(files);

  //loop through different files and create
  keys.forEach((key) => {
    const { path, txt, conditional } = files[key];

    //check if this particular file requires the user to pass a flag,
    //and if it does, check if the user actually passed it before creating the file
    if (conditional && !argv[conditional]) return;

    writeFile(path, txt.trim());
  });

  if (argv['c']) createCmd(cmd);
}

function writeFile(path, content) {
  //file with 755 permission
  fs.writeFile(path, content, { mode: 0o755 }, function (err) {
    if (err) throw err;
  });
}

function filesModule(dirPath) {
  return {
    index: {
      path: path.join(dirPath, 'index.js'),
      txt: `
        #!/usr/bin/env node
        const fs = require('fs');
        const path = require('path');
        const yargs = require('yargs/yargs');
        const { hideBin } = require('yargs/helpers');

        const argv = yargs(hideBin(process.argv)).argv;
    `,
    },
  };
}

//add cmd to bin and npm link so we can use the command anywhere without having to do 'node <cmd>'
async function createCmd(cmd) {
  const { pkgPath, pkgJson } = await getPkgJson();
  const { bin } = pkgJson;

  pkgJson['bin'] = { ...bin, [cmd]: `./scripts/${cmd}/index.js` };

  const _ = await writeFile(pkgPath, JSON.stringify(pkgJson));

  exec('npm link', {
    cwd: __dirname,
  });
}

async function getPkgJson() {
  const pkgPath = getPkgJsonPath();

  const pkg = await fs.promises.readFile(pkgPath);

  return { pkgJson: JSON.parse(pkg), pkgPath };
}

function getPkgJsonPath(basePath = __dirname) {
  const pkgPath = path.join(basePath, 'package.json');

  if (!fs.existsSync(pkgPath)) {
    return getPkgJsonPath(path.join(basePath, '..'));
  }

  return pkgPath;
}
