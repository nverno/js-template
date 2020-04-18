Integrate basic project setup: CI, test, formatting, git hooks, config files, packages, etc.

Either just copy files to repo or fork it and run

```sh
PACKAGES=path/to/other/package.json make packages.json
rm base-packages.json
```

To integrate an existing set of packages with the base ones (which just are used
for formatting, testing, linting, base react scripts via react-scripts).
