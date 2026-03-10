const path = require('path');
const axios = require("axios");
const { expect, use } = require('chai');
const matchApiSchema = require('api-contract-validator').chaiPlugin;

// API definitions path
const apiDefinitionsPath = path.join(__dirname, '../api.openapi.json'); 

// add as chai plugin
use(matchApiSchema({ apiDefinitionsPath }));

it('GET /api/dump/10477373803', async () => {
    const response = await axios.get('https://spansh.co.uk/api/dump/10477373803');
    expect(response).to.have.status(200).and.to.matchApiSchema();
})
