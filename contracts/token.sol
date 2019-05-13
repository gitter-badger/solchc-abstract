pragma solidity ^0.5.8;

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0);
		uint256 c = a / b;

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

contract Token{
	using SafeMath for uint256;

	mapping (address => uint256) private _balances;
	uint256 private _totalSupply;
	address _owner;

	event Transfer(address indexed from, address indexed to, uint256 value);

	constructor () public {
		_owner = msg.sender;
	}

	modifier onlyOwner {
		require(_owner == msg.sender);
		_;
	}

	function transfer(address to, uint256 value) public returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function mint(address to, uint256 value) public onlyOwner returns (bool) {
		_mint(to, value);
		return true;
	}

	function burn(address from, uint256 value) public onlyOwner returns (bool) {
		_burn(from, value);
		return true;
	}

	function _transfer(address from, address to, uint256 value) internal {
		require(to != address(0));

		uint256 supplyBefore = _totalSupply.sub(_balances[from]).sub(_balances[to]);
		_balances[from] = _balances[from].sub(value);
		_balances[to] = _balances[to].add(value);
		uint256 supplyAfter = supplyBefore.add(_balances[from]).add(_balances[to]);
		assert(supplyAfter == _totalSupply);
		emit Transfer(from, to, value);
	}

	function _mint(address account, uint256 value) internal {
		require(account != address(0));
		uint256 prevSupply = _totalSupply - _balances[account];
		_totalSupply = _totalSupply.add(value);
		_balances[account] = _balances[account].add(value);
		// Check that the modification to _account was also
		// applied to _totalSupply.
		assert(prevSupply + _balances[account] == _totalSupply);
		emit Transfer(address(0), account, value);
	}

	function _burn(address account, uint256 value) internal {
		require(account != address(0));
		uint256 prevSupply = _totalSupply - _balances[account];
		_totalSupply = _totalSupply.sub(value);
		_balances[account] = _balances[account].sub(value);
		// Check that the modification to _account was also
		// applied to _totalSupply.
		assert(prevSupply + _balances[account] == _totalSupply);
		emit Transfer(account, address(0), value);
	}
}
