#!/usr/bin/env node

import { parseArgs } from 'node:util';
import fs from 'node:fs';

import {
  bundleSchema,
  convertToJsonSchema
} from '../src/convert-schema.js';

const { values } = parseArgs({
  options: {
    schema: {
      type: 'string',
      short: 's'
    },
    base_json_schema: {
      type: 'string',
      short: 'b'
    }
  }
});

if (!values.schema) {
  console.error(
    'Usage: script -s <schema.yaml> [-b <base-schema.json>]'
  );
  process.exit(1);
}

const openApiSchema = await bundleSchema(values.schema);

const baseJsonSchema = values.base_json_schema
  ? JSON.parse(
      fs.readFileSync(values.base_json_schema, 'utf8')
    )
  : {};

const jsonSchema = convertToJsonSchema(
  openApiSchema,
  baseJsonSchema
);

console.log(JSON.stringify(jsonSchema, null, 2));
