const Web3 = require("web3");
const RelayerContract = artifacts.require("RelayerContract"); // Artifacts from the compiled contract
const web3 = new Web3("http://localhost:7545"); // URL to connect to your local Ganache

async function executeDemo() {
    const accounts = await web3.eth.getAccounts();
    const owner = accounts[0];

    // Get the deployed RelayerContract instance
    const contract = await RelayerContract.deployed();

    // Register two Ethereum nodes (replace node addresses with actual addresses)
    const node1 = accounts[1];
    const node2 = accounts[2];
    await contract.registerNode(node1, 5000000, { from: owner });
    await contract.registerNode(node2, 4000000, { from: owner });

    // Allow the first node to handle "eth_getBalance" requests
    await contract.allowNodeForMethod("eth_getBalance", [node1], { from: owner });

    // Execute a single JSON-RPC request
    const jsonRpcRequest = '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x407d73d8a49eeb85d32cf465507dd71d507100c1", "latest"],"id":1}';
    const response = await contract.executeJsonRpcRequest(jsonRpcRequest, { from: owner });
    console.log("Response:", response);

    // Execute a batch of JSON-RPC requests
    const batchRequests = [
        '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x407d73d8a49eeb85d32cf465507dd71d507100c1", "latest"],"id":1}',
        '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":2}',
    ];
    const batchResponse = await contract.executeBatchJsonRpcRequests(batchRequests, { from: owner });
    console.log("Batch Response:", batchResponse);
}

executeDemo().then(() => process.exit(0)).catch((err) => { console.error(err);
    process.exit(1); });