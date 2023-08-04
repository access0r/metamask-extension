const Web3 = require("web3");
const contractABI = require("./path_to_relayer_contract_abi.json"); // Replace with the actual path to the RelayerContract ABI JSON file
const contractAddress = "0x..."; // Replace with the actual address of the deployed RelayerContract
const web3Provider = "ws://localhost:8546"; // Replace with the WebSocket endpoint of your Ethereum node

const web3 = new Web3(web3Provider);

async function nodeRequest() {
    const accounts = await web3.eth.getAccounts();
    const owner = accounts[0];

    // Instantiate the RelayerContract
    const relayerContract = new web3.eth.Contract(contractABI, contractAddress);

    // Register two Ethereum nodes (replace node addresses with actual addresses)
    const node1 = accounts[1];
    const node2 = accounts[2];
    await relayerContract.methods.registerNode(node1, 5000000).send({ from: owner, gas: 200000 });
    await relayerContract.methods.registerNode(node2, 4000000).send({ from: owner, gas: 200000 });

    // Allow the first node to handle "eth_getBalance" requests
    await relayerContract.methods.allowNodeForMethod("eth_getBalance", [node1]).send({ from: owner, gas: 200000 });

    // Execute a single JSON-RPC request
    const jsonRpcRequest = '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x407d73d8a49eeb85d32cf465507dd71d507100c1", "latest"],"id":1}';
    const response = await relayerContract.methods.executeJsonRpcRequest(jsonRpcRequest).send({ from: owner, gas: 200000 });
    console.log("Response:", response);

    // Execute a batch of JSON-RPC requests
    const batchRequests = [
        '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x407d73d8a49eeb85d32cf465507dd71d507100c1", "latest"],"id":1}',
        '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":2}',
    ];
    const batchResponse = await relayerContract.methods.executeBatchJsonRpcRequests(batchRequests).send({ from: owner, gas: 400000 });
    console.log("Batch Response:", batchResponse);
}

nodeRequest().catch((err) => console.error(err));