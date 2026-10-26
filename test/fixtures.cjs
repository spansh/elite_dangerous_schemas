const path = require('path');
const { expect, use } = require('chai');
const matchApiSchema = require('api-contract-validator').chaiPlugin;

// API definitions path
const apiDefinitionsPath = path.join(__dirname, '../api.openapi.json');

// add as chai plugin
use(matchApiSchema({ apiDefinitionsPath }));

// Saved API responses, for fields that come and go in the live data and so can't be relied on in test/api.cjs
const fixtures = [
  {
    // power_conflict_progress: only while powers are fighting over the system
    file: 'system_power_conflict.json',
    method: 'get',
    path: '/api/system/44870666611',
    field: 'power_conflict_progress'
  }
];

for (const fixture of fixtures) {
  it(`${fixture.method.toUpperCase()} ${fixture.path} (saved in ${fixture.file}) passes OpenAPI check`, () => {
    const data = require(path.join(__dirname, 'fixtures', fixture.file));
    // The record must still have the field it's here to test
    expect(data.record).to.have.property(fixture.field).that.is.not.empty;
    // Shaped like an axios response, as test/api.cjs checks
    const response = {
      status: 200,
      headers: { 'content-type': 'application/json' },
      data,
      config: { method: fixture.method },
      request: { path: fixture.path }
    };
    expect(response).to.have.status(200).and.to.matchApiSchema();
  });
}
