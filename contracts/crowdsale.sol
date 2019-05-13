pragma solidity ^0.5.0;

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

interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address who) external view returns (uint256);

	function allowance(address owner, address spender)
		external view returns (uint256);

	function transfer(address to, uint256 value) external returns (bool);

	function approve(address spender, uint256 value)
		external returns (bool);

	function transferFrom(address from, address to, uint256 value)
		external returns (bool);

	event Transfer(
		address indexed from,
		address indexed to,
		uint256 value
	);

	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

contract ReentrancyGuard {
	uint256 private _guardCounter;

	constructor() internal {
		_guardCounter = 1;
	}

	modifier nonReentrant() {
		_guardCounter += 1;
		uint256 localCounter = _guardCounter;
		_;
		require(localCounter == _guardCounter);
	}

}

contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 private _token;

    address payable private _wallet;

    uint256 private _rate;

    uint256 private _weiRaised;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0);
        require(wallet != address(0));
        require(address(token) != address(0));

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function wallet() public view returns (address payable) {
        return _wallet;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        uint256 tokens = _getTokenAmount(weiAmount);

        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0);
    }

    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}

contract CappedCrowdsale is Crowdsale {
	using SafeMath for uint256;

	uint256 private _cap;

	constructor(uint256 cap) internal {
		require(cap > 0);
		_cap = cap;
	}

	function cap() public view returns(uint256) {
		return _cap;
	}

	function capReached() public view returns (bool) {
		return weiRaised() >= _cap;
	}

	function _preValidatePurchase(
		address beneficiary,
		uint256 weiAmount
	)
		internal
		view
	{
		super._preValidatePurchase(beneficiary, weiAmount);
		require(weiRaised().add(weiAmount) <= _cap);
	}

}

contract FinalizableCrowdsale {
	using SafeMath for uint256;

	bool private _finalized;

	event CrowdsaleFinalized();

	constructor() internal {
		_finalized = false;
	}

	function finalized() public view returns (bool) {
		return _finalized;
	}

	function finalize() public {
		require(!_finalized);

		_finalized = true;

		_finalization();
		emit CrowdsaleFinalized();
	}

	function _finalization() internal {
	}
}

contract ERC20 is IERC20 {
	using SafeMath for uint256;

	mapping (address => uint256) private _balances;

	mapping (address => mapping (address => uint256)) private _allowed;

	uint256 private _totalSupply;

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address owner) public view returns (uint256) {
		return _balances[owner];
	}

	function allowance(address owner, address spender) public view returns (uint256) {
		return _allowed[owner][spender];
	}

	function transfer(address to, uint256 value) public returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function approve(address spender, uint256 value) public returns (bool) {
		_approve(msg.sender, spender, value);
		return true;
	}

	function transferFrom(address from, address to, uint256 value) public returns (bool) {
		_transfer(from, to, value);
		_approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
		return true;
	}

	function _transfer(address from, address to, uint256 value) internal {
		require(to != address(0));

		_balances[from] = _balances[from].sub(value);
		_balances[to] = _balances[to].add(value);
		emit Transfer(from, to, value);
	}

	function _mint(address account, uint256 value) internal {
		require(account != address(0));

		_totalSupply = _totalSupply.add(value);
		_balances[account] = _balances[account].add(value);
		emit Transfer(address(0), account, value);
	}

	function _burn(address account, uint256 value) internal {
		require(account != address(0));

		_totalSupply = _totalSupply.sub(value);
		_balances[account] = _balances[account].sub(value);
		emit Transfer(account, address(0), value);
	}

	function _approve(address owner, address spender, uint256 value) internal {
		require(spender != address(0));
		require(owner != address(0));

		_allowed[owner][spender] = value;
		emit Approval(owner, spender, value);
	}

	function _burnFrom(address account, uint256 value) internal {
		_burn(account, value);
		_approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
	}
}

contract SampleCrowdsale is CappedCrowdsale, FinalizableCrowdsale {
	constructor (
		uint256 rate,
		address payable wallet,
		uint256 cap,
		ERC20 token,
		uint256 goal
	)
		public
		Crowdsale(rate, wallet, token)
		CappedCrowdsale(cap)
	{
		require(goal <= cap);
	}

	function _finalization() internal {
		assert(weiRaised() <= cap());
	}

	function _postValidatePurchase() internal {
		assert(weiRaised() <= cap());
	}
}
