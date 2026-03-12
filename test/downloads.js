const path = require('path');
const axios = require("axios");
const { expect, use } = require('chai');
const matchApiSchema = require('api-contract-validator').chaiPlugin;

// Downloads definitions path
const downloadsDefinitionsPath = path.join(__dirname, '../galaxy_downloads.openapi.json'); 


// add as chai plugin
use(matchApiSchema({ apiDefinitionsPath: downloadsDefinitionsPath }));

const requests = [
    {
        method: 'get',
        path: '/galaxy_sol_shinrarta_colonia.json'
    },
    {
        method: 'get',
        path: '/systems_1day.json'
    }
];

for (const request of requests) {
    it(`${request.method.toUpperCase()} ${request.path} passes OpenAPI check`, async () => {
        const response = await axios[request.method](`https://downloads.spansh.co.uk${request.path}`);
        expect(response).to.be.successful().and.to.matchApiSchema();
    }).timeout(60000);
}
