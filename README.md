# Elite Dangerous: Index Schemas

A set of schemas to help dealing with data produced by https://spansh.co.uk/

## Description

These schema files can be used to validate the data which can be downloaded from https://spansh.co.uk/.  The most recent version of these schemas can always be downloaded from the following links.

* <https://docs.spansh.co.uk/api.openapi.json> OpenAPI 3.1
* <https://docs.spansh.co.uk/model.openapi.json> OpenAPI 3.1
* <https://docs.spansh.co.uk/systems.schema.json> JSON Schema Draft 4
* <https://docs.spansh.co.uk/galaxy.schema.json> JSON Schema Draft 4
* <https://docs.spansh.co.uk/factions.schema.json> JSON Schema Draft 4

However, old versions of each of these schemas can be downloaded via the putting the relevant values into following link.

* <https://docs.spansh.co.uk/[version]/[file]>

For example

* https://docs.spansh.co.uk/2.0.1/galaxy.schema.json
* https://docs.spansh.co.uk/2.1.0/api.openapi.json

## Usage

If you have the [pnpm package manager](https://pnpm.io/) (recommended) you can validate a schema file like so, though it is limited in memory usage.

```
pnpm dlx --package ajv-cli --package ajv --package ajv-formats ajv validate -c ajv-formats -s galaxy.schema.json -d galaxy.json
```

I do also have a C++ schema validator using [RapidJSON](https://rapidjson.org/md_doc_schema.html) which streams the file and can process the whole galaxy dump.  If there is a lot of interest for people to use that I can share the code for that.

## Version History

Patch versions will only ever add entries to enum fields, reduce validation rules or correct typographical errors.
Minor versions may add new fields.
Major versions will contain breaking changes.

* 1.0.1
    * Initial Release
* 1.0.2
    * Switch to draft 4 of JSON Schema
* 1.2.0
    * Add enum to genuses, remove maximum from powerConflictProgress
* 1.3.0
    * Added mostly deprecated Thargoid fields
* 1.3.1
    * Fix typo in description
    * Allow nulls for controllingFaction 
    * Rremoved minimum value for powerStateControlProgress
* 1.4.0
    * Fixed extra type declaration
* 1.5.0
    * Added new faction state fields
    * Consolidated faction definition
* 1.5.1
    * Updated descriptions of faction states
    * Removed duplicated type attribute
* 2.0.0
    * Converted schemas to OpenAPI 3.1
    * Added description of /dump/{id64}
    * Added description of /system/{id64}
    * Added description of /body/{id64}
    * Added tests for each of the schemas
    * Created downgrade scripts to convert the OpenAPI 3.1 to JSON Schema Draft 4
* 2.1.0
    * Added description of /system/{marketId}
    * Recovered test files
* 2.1.1
    * Updated README.md to reflect current values
* 2.2.0
    * Added Lynx Highliner
    * Added Mk II Passenger Cabins
    * Added schema for faction download
* 2.3.0
    * Fix broken $id and $schema

## See Also

* [Elite: Dangerous Index](https://spansh.co.uk)
* [Galaxy Dumps](https://spansh.co.uk/dumps)
* [Spansh API Documentation](https://docs.spansh.co.uk/)
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

