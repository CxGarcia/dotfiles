#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

const argv = yargs(hideBin(process.argv)).option('test', {
  alias: 't',
  type: 'boolean',
  description: 'add test files',
}).argv;

const basePath = fs.existsSync('./src')
  ? path.resolve('src', 'components')
  : fs.existsSync('./components')
  ? path.resolve('components')
  : '.';

for (const arg of argv['_']) {
  const [first, ...rest] = arg;
  const componentName = first.toUpperCase() + rest.join('');
  const dirPath = path.join(basePath, componentName);

  //skip dir creation if it already exists
  if (fs.existsSync(dirPath)) {
    console.log(
      `${componentName} already exists at: ${dirPath} - will skip its creation until the directory is deleted`
    );

    continue;
  }

  //create dir
  fs.mkdirSync(dirPath);

  //create files module
  const files = filesModule(componentName, dirPath);
  const keys = Object.keys(files);

  //loop through different files and create
  keys.forEach((key) => {
    const { path, content, conditional } = files[key];

    //check if this particular file requires the user to pass a flag,
    //and if it does, check if the user actually passed it before creating the file
    if (conditional && !argv[conditional]) return;
    createFile(path, content);
  });

  console.log(`${componentName} has been created successfully at: ${dirPath}`);
}

function createFile(path, content) {
  fs.writeFile(path, content, function (err) {
    if (err) throw err;
  });
}

function filesModule(componentName, dirPath) {
  const filePath = path.join(dirPath, componentName);

  return {
    barrel: {
      path: path.join(dirPath, 'index.js'),
      content: `
      import ${componentName} from './${componentName}';

      export default ${componentName};
    `,
    },
    component: {
      path: `${filePath}.js`,
      content: `
      import React from 'react';
      import styles from './${componentName}.module.scss';

      function ${componentName}({}) {
        return <div></div>;
      }

      export default ${componentName};
    `,
    },
    test: {
      path: `${filePath}.test.js`,
      conditional: 't',
      content: `
      import { render, screen } from '@testing-library/react';
      import ${componentName} from './${componentName}';

      test('first test', () => {
        render(<${componentName} />);
      });
    `,
    },
    scss: {
      path: `${filePath}.module.scss`,
      content: "@import 'styles/main.scss';",
    },
  };
}
