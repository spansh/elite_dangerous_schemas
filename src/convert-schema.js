import {
  bundle,
  createConfig
} from '@redocly/openapi-core';

import {
  openapiSchemaToJsonSchema
} from '@openapi-contrib/openapi-schema-to-json-schema';

export async function bundleSchema(filename, config = null) {
  config ??= await createConfig({});

  const result = await bundle({
    ref: filename,
    config
  });

  if (result.problems?.length) {
    for (const problem of result.problems) {
      console.warn(problem.message);
    }
  }

  return result.bundle.parsed;
}

function rewriteRefs(value) {
  if (Array.isArray(value)) {
    return value.map(rewriteRefs);
  }

  if (value !== null && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, childValue]) => {
        if (
          key === '$ref' &&
          typeof childValue === 'string' &&
          childValue.startsWith('#/components/schemas/')
        ) {
          return [
            key,
            childValue.replace(
              '#/components/schemas/',
              '#/definitions/'
            )
          ];
        }

        return [key, rewriteRefs(childValue)];
      })
    );
  }

  return value;
}

function convertNullableStrings(value) {
  if (Array.isArray(value)) {
    return value.map(convertNullableStrings);
  }

  if (value !== null && typeof value === 'object') {
    const converted = Object.fromEntries(
      Object.entries(value).map(([key, childValue]) => [
        key,
        convertNullableStrings(childValue)
      ])
    );

    if (
      converted.nullable === true &&
      converted.type === 'string'
    ) {
      converted.type = ['string', 'null'];
    }

    return converted;
  }

  return value;
}

// bash -c "
//  pnpm --package=@openapi-contrib/openapi-schema-to-json-schema dlx openapi-schema-to-json-schema --input
//    <(cat
//      <(pnpm dlx node-jq 'del(.definitions, .type, .items)' galaxy.schema.json)
//      <(pnpm --package=@redocly/cli dlx redocly bundle --ext json galaxy.downloads.openapi.json | pnpm dlx node-jq '.paths[\"/{filename}\"].get.responses[\"200\"].content[\"application/json\"].schema,{definitions:.components.schemas}')
//  | pnpm dlx node-jq -s add | sed -e 's/#\/components\/schemas\//#\/definitions\//') --output galaxy.old.schema.json"
export function convertToJsonSchema(schema, baseSchema = null) {
  if (!baseSchema) {
    return rewriteRefs(
      openapiSchemaToJsonSchema(schema)
    );
  }

  const {
    $ref,
    definitions,
    type,
    items,
    ...cleanBaseSchema
  } = baseSchema;

  const responseSchema =
    schema.paths['/{filename}']
      .get
      .responses['200']
      .content['application/json']
      .schema;

  const convertedDefinitions = convertNullableStrings(
    schema.components.schemas
  );

  const convertedSchema = {
    ...cleanBaseSchema,
    $ref: responseSchema.$ref,
    definitions: convertedDefinitions
  };

  return rewriteRefs(convertedSchema);
}
