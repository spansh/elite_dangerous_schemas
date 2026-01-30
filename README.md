# Elite Dangerous: Index Schemas

A set of schemas to help dealing with data produced by https://spansh.co.uk/

## Description

These schema files can be used to validate the data which can be downloaded from https://spansh.co.uk/.  The most recent version of these schemas can always be downloaded from the following links.

* https://downloads.spansh.co.uk/schemas/galaxy.schema.json
* https://downloads.spansh.co.uk/schemas/systems.schema.json

However, specific versions of each of these schemas can be downloaded via the following links.

* <https://downloads.spansh.co.uk/schemas/[version]/galaxy.schema.json>
* <https://downloads.spansh.co.uk/schemas/[version]/systems.schema.json>

For example

* https://downloads.spansh.co.uk/schemas/1.0.1/galaxy.schema.json
* https://downloads.spansh.co.uk/schemas/1.0.1/systems.schema.json

## Usage

If you have the [pnpm package manager](https://pnpm.io/) (recommended) you can validate a schema file like so, though it is limited in memory usage.

```
pnpm dlx --package ajv-cli --package ajv --package ajv-formats ajv validate -c ajv-formats -s galaxy.schema.json -d galaxy.json
```

I do also have a C++ schema validator using [RapidJSON](https://rapidjson.org/md_doc_schema.html) which streams the file and can process the whole galaxy dump.  If there is a lot of interest for people to use that I can share the code for that.

## Version History

Patch versions will only ever add entries to enum fields, minor versions may add new fields, major versions will contain breaking changes.

* 1.0.1
    * Initial Release
* 1.0.2
    * Switch to draft 4 of JSON Schema
* 1.2.0
    * Add enum to genuses, remove maximum from powerConflictProgress

## See Also

* [Elite: Dangerous Index](https://spansh.co.uk)
* [Galaxy Dumps](https://spansh.co.uk/dumps)
* [Elite: Dangerous Commnunity Developers Discord](https://discord.gg/RyHVFcF)
* [JSON schema](https://json-schema.org/)
* [AJV schema validator](https://ajv.js.org/)
* [RapidJSON](https://rapidjson.org/)

## License

The MIT License (MIT)

Copyright (c) 2025 Gareth Harper

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

