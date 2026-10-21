# About this Documentation

This documentation is dynamic, generated from markdown files templatised with jinja. Changes to architecture or configuration can yield this document obsolete. To make any changes update the templates under `_docs/templates` and follow the instructions below to generate.

## How it works?

1. A script get-outputs.sh generates an output file in JSON format per Terraform workspace. These files are stored in `_workspaces/<stack>/<env>/.outputs.json`

2. A python script under `_docs/main.py` combines all output JSON files and one.yaml for all stacks into one JSON file: `_docs/.data.json`

3. Using a tool called *mkdocs*, it will read all markdown files under `_docs/docs`, replace the tokens (using Jinja) with values from `.data.yml` and generate the final documentation.

4. The final documentation can be found at `_docs/site` and `_docs/site/pdf/document.pdf`.

## Generating this Documentation

Open a terminal and change folder to `_docs` of this repo.

Authenticate with AWS and run:
```bash
get-outputs.sh
```
It will run `terragrunt output` and generate an `.outputs.json` on each workspace.

Building the docs
```bash
make build
```

Serve locally for development
```bash
make serve
```

Only generate .data.json
```bash
make clean .data.json
```