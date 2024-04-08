const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const QuickQuid = artifacts.require('QuickQuid');

module.exports = async function (deployer) {
    await deployProxy(QuickQuid, {
        deployer,
        kind: 'uups',
    });
};