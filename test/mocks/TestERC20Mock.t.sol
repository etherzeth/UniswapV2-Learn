// SPDX-License-Identifier:MIT
pragma solidity ^0.8.28;

import {IERC20} from "../../src/core/interfaces/IERC20.sol";
import {Context} from "../utils/Context.sol";
import {IERC20Errors} from "../utils/IERC20Errors.sol"; // Mock

abstract contract MockERC20 is IERC20, Context, IERC20Errors {
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowance;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        // _mint(msg.sender, _initialSupply);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public view virutal returns (bool) {
        address owner = _msgsender();
        _transfer(owner, to, value);
        return true;
    }
}