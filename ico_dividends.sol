pragma solidity ^0.4.11;

contract MBToken {

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _tokenPrice;
    bool public _allowManualTokensGeneration;
    uint256 public shareholdersBalance;
    uint public totalShareholders;
    mapping (address => bool) registeredShareholders;
    mapping (uint => address) shareholders;
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function MBToken(string tokenName, string tokenSymbol, uint8 tokenDecimals, uint256 tokenStartBalance, uint tokenPrice, bool allowManualTokensGeneration) {
        balanceOf[msg.sender] = tokenStartBalance;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        _tokenPrice = tokenPrice;
        _allowManualTokensGeneration = allowManualTokensGeneration;
        owner = msg.sender;
        totalShareholders = 0;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) returns (bool) {
        if (balanceOf[msg.sender] < _value) return false;              // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;    // Check for overflows
        balanceOf[msg.sender] -= _value;                        // Subtract from the sender
        balanceOf[_to] += _value;                               // Add the same to the recipient

        /* Adding to shareholders count if tokens spent from owner to others */
        if (msg.sender == owner && _to != owner) {
            shareholdersBalance += _value;
        }
        /* Remove from shareholders count if tokens spent from holder to owner */
        if (msg.sender != owner && _to == owner) {
            shareholdersBalance -= _value;
        }

        if (owner == _to) {
            // sender is owner
        } else {
            insertShareholder(_to);
        }

        /* Notify anyone listening that this transfer took place */
        Transfer(msg.sender, _to, _value);

        return true;
    }

    function addSomeTokens(uint256 numTokens) onlyOwner {
        if (_allowManualTokensGeneration) {
            balanceOf[msg.sender] += numTokens;
            Transfer(0, msg.sender, numTokens);
        } else {
            throw;
        }
    }

    /* Buy Token 1 token for 1 ether */
    function mint() payable external {
        if (msg.value == 0) throw;
        if (msg.value < _tokenPrice) throw;
        var numTokens = msg.value / _tokenPrice;
        balanceOf[msg.sender] += numTokens;
        Transfer(0, msg.sender, numTokens);

        if (msg.sender != owner) {
            shareholdersBalance += numTokens;
        }
    }

    function payDividends() onlyOwner {
        if (this.balance > 0 && totalShareholders > 0) {
            uint256 balance = this.balance;
            for (uint i = 1; i <= totalShareholders; i++) {
                uint256 currentBalance = balanceOf[shareholders[i]];
                if (currentBalance > 0) {
                    uint256 amount = balance * currentBalance / shareholdersBalance;
                    shareholders[i].transfer(amount);
                }
            }
        }
    }

    function receiveFunds() payable {}

    function insertShareholder(address _shareholder) internal returns (bool) {
        if (registeredShareholders[_shareholder] == true) {

        } else {
            totalShareholders += 1;
            shareholders[totalShareholders] = _shareholder;
            registeredShareholders[_shareholder] = true;
            return true;
        }
        return false;
    }
}
