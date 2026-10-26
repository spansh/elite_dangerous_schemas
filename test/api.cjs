const path = require('path');
const axios = require("axios");
const { expect, use } = require('chai');
const matchApiSchema = require('api-contract-validator').chaiPlugin;

// API definitions path
const apiDefinitionsPath = path.join(__dirname, '../api.openapi.json'); 


// add as chai plugin
use(matchApiSchema({ apiDefinitionsPath }));

const requests = [
    {
      resultKey: 'system',
      attributes: {
        name: 'Sol',
      },
      method: 'get',
      path: '/api/dump/10477373803'
    },
    {
      resultKey: 'record',
      attributes: {
        name: 'Sol',
      },
      method: 'get',
      path: '/api/system/10477373803'
    },
    {
      resultKey: 'record',
      attributes: {
        name: 'Sol',
      },
      method: 'get',
      path: '/api/body/10477373803'
    },
    {
      resultKey: 'record',
      attributes: {
        name: 'Fuelum A 8 e',
      },
      method: 'get',
      path: '/api/body/828667363158102746'
    },
    {
      resultKey: 'record',
      attributes: {
        name: 'Jameson Memorial',
      },
      method: 'get',
      path: '/api/station/128666762'
    },
    {
      // nearest_populated_distance
      resultKey: 'record',
      attributes: {
        name: 'Gloaduae IK-A d1',
      },
      method: 'get',
      path: '/api/system/44770561795'
    },
    {
      // genuses
      resultKey: 'record',
      attributes: {
        name: 'Plua Thua NY-R e4-0 B 10 b',
      },
      method: 'get',
      path: '/api/body/900719927158146092'
    },
    {
      // body_has_atmosphere
      resultKey: 'record',
      attributes: {
        name: "Zel'dovich Hub",
      },
      method: 'get',
      path: '/api/station/4324402435'
    }
];

for (const request of requests) {
  it(`${request.method.toUpperCase()} ${request.path} passes OpenAPI check`, async () => {
    const response = await axios[request.method](`https://spansh.co.uk${request.path}`);
    expect(response).to.have.status(200).and.to.matchApiSchema();
    for (const attribute in request.attributes) {
      expect(response.data).to.have.property(request.resultKey);
      expect(response.data[request.resultKey][attribute]).to.equal(request.attributes[attribute]);
    }
  })
}
