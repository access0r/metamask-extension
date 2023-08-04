// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Access Control Library
import "@openzeppelin/contracts/access/Ownable.sol";

// Interface for the Ethereum node
interface NodeInterface {
    function executeJsonRpcRequests(string[] calldata _jsonRpcRequests) external payable returns (bool[] memory success, string[] memory responses);
}

// Relayer contract
contract RelayerContract is Ownable {
    struct Node {
        address nodeAddress;
        bool isActive;
        uint256 maxGasPrice; // Maximum gas price (in Wei) accepted by the node
    }

    // Mapping of JSON-RPC methods to the allowed node addresses
    mapping(string => address[]) private allowedNodes;

    // List of all registered nodes
    Node[] public nodes;

    // Whitelist of allowed contracts to interact with the relayer
    mapping(address => bool) public allowedContracts;

    // Event emitted when a new node is registered
    event NodeRegistered(address indexed nodeAddress, uint256 maxGasPrice);

    // Event emitted when a node is set as active or inactive
    event NodeStatusChanged(address indexed nodeAddress, bool isActive);

    // Event emitted when a contract is added or removed from the whitelist
    event AllowedContractUpdated(address indexed contractAddress, bool isAllowed);

    // Constructor to set the contract owner
    constructor() {
        // Set the contract deployer as the owner
        transferOwnership(msg.sender);
    }

    // Register a new node
    function registerNode(address _nodeAddress, uint256 _maxGasPrice) external onlyOwner {
        require(_nodeAddress != address(0), "Invalid node address");
        require(_maxGasPrice > 0, "Invalid max gas price");
        nodes.push(Node(_nodeAddress, true, _maxGasPrice));
        emit NodeRegistered(_nodeAddress, _maxGasPrice);
    }

    // Set the status of a node (active or inactive)
    function setNodeStatus(address _nodeAddress, bool _isActive) external onlyOwner {
        require(_nodeAddress != address(0), "Invalid node address");
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i].nodeAddress == _nodeAddress) {
                nodes[i].isActive = _isActive;
                emit NodeStatusChanged(_nodeAddress, _isActive);
                return;
            }
        }
        revert("Node not found");
    }

    // Associate a JSON-RPC method with allowed node addresses
    function allowNodeForMethod(string calldata _jsonRpcMethod, address[] calldata _allowedNodes) external onlyOwner {
        require(_allowedNodes.length > 0, "At least one node address required");
        allowedNodes[_jsonRpcMethod] = _allowedNodes;
    }

    // Add or remove a contract from the whitelist
    function updateAllowedContract(address _contractAddress, bool _isAllowed) external onlyOwner {
        allowedContracts[_contractAddress] = _isAllowed;
        emit AllowedContractUpdated(_contractAddress, _isAllowed);
    }

    // Execute batch JSON-RPC requests on an allowed node
    function executeBatchJsonRpcRequests(string[] calldata _jsonRpcRequests) external returns (string[] memory) {
        address sender = msg.sender;
        require(allowedContracts[sender], "Contract not allowed");
        require(_jsonRpcRequests.length > 0, "Empty batch requests");

        string[] memory responses = new string[](_jsonRpcRequests.length);
        for (uint256 i = 0; i < _jsonRpcRequests.length; i++) {
            responses[i] = executeJsonRpcRequest(_jsonRpcRequests[i]);
        }
        return responses;
    }

    // Execute a JSON-RPC request on an allowed node
    function executeJsonRpcRequest(string calldata _jsonRpcRequest) public returns (string memory) {
        address sender = msg.sender;
        require(allowedContracts[sender], "Contract not allowed");
        require(allowedNodes[_getJsonRpcMethod(_jsonRpcRequest)].length > 0, "Method not allowed");
        
        for (uint256 i = 0; i < allowedNodes[_getJsonRpcMethod(_jsonRpcRequest)].length; i++) {
            address nodeAddress = allowedNodes[_getJsonRpcMethod(_jsonRpcRequest)][i];
            require(_isNodeActive(nodeAddress), "Node is not active");

            uint256 maxGasPrice = nodes[i].maxGasPrice;
            require(tx.gasprice <= maxGasPrice, "Gas price exceeds limit");

            (bool success, string memory response) = NodeInterface(nodeAddress).executeJsonRpcRequests{value: msg.value}([_jsonRpcRequest]);
            if (success) {
                return response;
            }
        }
        revert("All nodes failed to execute the request");
    }

    // Internal function to extract JSON-RPC method from the request
    function _getJsonRpcMethod(string memory _jsonRpcRequest) internal pure returns (string memory) {
        // Implement logic to extract JSON-RPC method from the request
        // For example, you can use regular expressions to parse the method
        // For simplicity, we assume the JSON-RPC method is the first word in the request.
        bytes memory requestBytes = bytes(_jsonRpcRequest);
        uint256 spaceIndex = 0;
        while (requestBytes[spaceIndex] != 0x20 && spaceIndex < requestBytes.length) {
            spaceIndex++;
        }
        return string(requestBytes[0:spaceIndex]);
    }

    // Internal function to check if a node is active
    function _isNodeActive(address _nodeAddress) internal view returns (bool) {
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i].nodeAddress == _nodeAddress) {
                return nodes[i].isActive;
            }
        }
        return false;
    }
}
