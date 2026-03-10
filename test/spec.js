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
        method: 'get',
        path: '/api/dump/10477373803'
    },
    {
        method: 'get',
        path: '/api/system/10477373803'
    }
];

for (const request of requests) {
    it(`${request.method.toUpperCase()} ${request.path}`, async () => {
        const response = await axios[request.method](`https://spansh.co.uk${request.path}`);
        expect(response).to.have.status(200).and.to.matchApiSchema();
    })
}
