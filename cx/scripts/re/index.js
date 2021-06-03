#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const cwd = process.cwd();

//filter out flags from args array
const filteredArgs = args.filter((arg) => !arg.startsWith('-'));

const basePath = path.resolve('src', 'components');

for (const arg of filteredArgs) {
  const [first, ...rest] = arg;
  const componentName = first.toUpperCase() + rest.join('');
  const dir = path.join(basePath, componentName);
  const file = path.join(dir, componentName);
  const txt = txtModule(componentName);

  //skip dir creation if it already exists
  if (fs.existsSync(dir)) {
    console.log(
      `${componentName} already exists at: ${dir} - will skip its creation until the directory is deleted`
    );

    continue;
  }

  //create dir
  fs.mkdirSync(dir);

  //create js file
  fs.appendFile(`${file}.js`, txt['component'], function (err) {
    if (err) throw err;
  });

  //scss module
  fs.appendFile(`${file}.module.scss`, txt['scss'], function (err) {
    if (err) throw err;
  });

  //test file
  if (args.includes('-t')) {
    fs.appendFile(`${file}.test.js`, txt['test'], function (err) {
      if (err) throw err;
    });
  }

  //barrel roll
  fs.appendFile(path.join(dir, 'index.js'), txt['barrel'], function (err) {
    if (err) throw err;
  });

  console.log(`${componentName} has been created successfully at: ${dir}`);
}

function txtModule(componentName) {
  return {
    barrel: `
      import ${componentName} from './${componentName}';

      export default ${componentName};
    `,
    component: `
      import React from 'react';
      import styles from './${componentName}.module.scss';

      function ${componentName}({}) {
        return <div></div>;
      }

      export default ${componentName};
    `,
    test: `
      import { render, screen } from '@testing-library/react';
      import ${componentName} from './${componentName}';

      test('first test', () => {
        render(<${componentName} />);
      });
    `,
    scss: "@import 'styles/main.scss';",
  };
}
