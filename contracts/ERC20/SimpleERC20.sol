// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleERC20 {
    uint8 constant _decimals = 18;               
    string _name;                                   //0
    string _symbol;                                 //1
    uint _totalSupply;                              //3
    mapping (address => uint) _balances;            //4
    mapping(address owner => mapping(address spender => uint value)) _allowances;
    address immutable contractOwner;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed from, address indexed to, uint value);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "only Owner");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        contractOwner = msg.sender;
        _name = name_;
        _symbol = symbol_;
    }

    function decimals() external virtual view returns(uint8) {
        return _decimals;
    }

    function name() external virtual view returns(string memory) {
        return _name;
    }

    function symbol() external virtual view returns(string memory) {
        return _symbol;
    }

    function totalSupply() external virtual view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external virtual view returns(uint) {
        return _balances[account];
    }

    function transfer(address to, uint value) external virtual returns(bool) {
        _transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint value) external virtual returns(bool) {
        uint currentValue = _allowances[from][msg.sender];
        require(currentValue >= value, "not enough allowance");
        _transfer(from, to, value);
        _approve(from, msg.sender, currentValue - value, true);
        emit Transfer(from, to, value);
        
        return true;
    }

    function _transfer(address from, address to, uint value) internal virtual {
        require(from != address(0), "bad from");
        require(to != address(0), "bad to");
        _update(from, to, value);
    }

    function allowance(address owner, address spender) external virtual view returns(uint amount) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint value) external virtual returns(bool){
        uint currentValue = _allowances[msg.sender][spender]; 

        _approve(msg.sender, spender, currentValue + value);
        return true;
    }

    function decreaseAllowance(address spender, uint value) external virtual returns(bool){
        uint currentValue = _allowances[msg.sender][spender];
        require(currentValue >= value, "incorrect value");

        _approve(msg.sender, spender, currentValue - value);
        return true;
    }

    function approve(address spender, uint value) external virtual returns(bool){
        _approve(msg.sender, spender, value);
        return true;
    }

    function _approve(address owner, address spender, uint value) internal virtual {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint value, bool emitEvent) internal virtual {
        require(owner != address(0), "bad owner");
        require(spender != address(0), "bad spender");

        _allowances[owner][spender] = value;

        if(emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function mint(address to, uint value) public virtual onlyOwner{
        _update(address(0), to, value);
    }

    function burn(uint value) external virtual returns(bool){
        _burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint value) external virtual returns(bool){
        uint currentValue = _allowances[from][msg.sender];
        require(currentValue >= value, "not enough allowance");
        _burn(from, value);
        _approve(from, msg.sender, currentValue - value, true);
        return true;
    }

    function _burn(address from, uint value ) internal virtual {
        _update(from, address(0), value);
    }

    function _update(address from, address to, uint value) internal virtual {
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            require(_balances[from] >= value, "not enough");
            _balances[from] -= value;
        }
    
        if (to == address(0)) {
            _totalSupply -= value;
        } else {
            _balances[to] += value;
        }
    }
}