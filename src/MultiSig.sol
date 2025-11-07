// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MultiSigWallet {
    /* Errors */
    error NotOwner();
    error OwnersRequired();
    error RequiredNumberOfOwners();
    error ExecutionFailed();

    /* Events */
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    /* array of owners */
    address[] public owners;
    /* mapping to check if an address is an owner */
    mapping(address => bool) public isOwner;
    /* number of owners that must approve a transaction */
    uint public required;

    /* array of transactions */
    Transaction[] public transactions;
    /* mapping to check if an owner has approved a transaction
     * txId (index of the transaction) => owner => bool
     */
    mapping(uint => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "Already approved");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "Transaction executed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, OwnersRequired());
        require(
            _required > 0 && _required <= _owners.length,
            "invalid required number of owners"
        );

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(
        address _to,
        uint _value,
        bytes calldata _data
    ) external onlyOwner {
        require(_to != address(0), "Invalid to address");
        require(_value > 0, "Invalid value");
        require(_data.length > 0, "Invalid data");

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit Submit(transactions.length - 1);
    }

    function approve(
        uint _txId
    ) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        transactions[_txId].numConfirmations++;

        emit Approve(msg.sender, _txId);
    }

    function execute(uint _txId) external txExists(_txId) notExecuted(_txId) {
        require(
            transactions[_txId].numConfirmations >= required,
            "Not enough confirmations"
        );

        Transaction storage tx = transactions[_txId];

        (bool success, ) = tx.to.call{value: tx.value}(tx.data);

        if (!success) revert ExecutionFailed();

        tx.executed = true;

        emit Execute(_txId);
    }

    function revoke(
        uint _txId
    ) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender], "Sender not approved");

        approved[_txId][msg.sender] = false;
        transactions[_txId].numConfirmations--;

        emit Revoke(msg.sender, _txId);
    }
}
