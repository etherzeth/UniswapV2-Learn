pragma solidity ^0.8.18;

import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {UniswapV2ERC20} from "./UniswapV2ERC20.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {UniswapV2Factory} from "./UniswapV2Factory.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Callee} from "./interfaces/IUniswapV2Callee.sol";
import {Math} from "./libraries/Math.sol";

contract UniswapV2Pair is UniswapV2ERC20, IUniswapV2Pair {
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3; // 1000
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)"))); // function selector : 0xa9059cbb

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimeStampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    
    uint256 public kLast;

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "UniswapV2:Locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimeStampLast) {
        return (reserve0, reserve1, blockTimeStampLast);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "UniswapV2:Transfer_Failed");
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, "UniswapV2:FORBIDDEN");
        token0 = _token0;
        token1 = _token1;
    }

    // it's a function that update reserve
    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 < type(uint112).max, "UniswapV2:OVERFLOW");
        uint32 blockTimeStamp = uint32(block.timestamp % 2 ** 32); // 2 ** 32 = 4,294,967,296
        uint32 timeElapsed = blockTimeStamp - blockTimeStampLast;

        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            uint256 price0 = (uint256(_reserve1) * 1e18) / uint256(_reserve0);
            uint256 price1 = (uint256(_reserve0) * 1e18) / uint256(_reserve1);

            price0CumulativeLast += price0 * timeElapsed;
            price1CumulativeLast += price1 * timeElapsed;
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimeStampLast = blockTimeStamp;
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // to save Gas
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0) * uint256(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);

                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);
                    uint256 denominator = (rootK * 5) + rootKLast;

                    uint256 liquidity = numerator / denominator;

                    if (liquidity > 0) {
                        _mint(feeTo, liquidity);
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }
    
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;

            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min((amount0 * _totalSupply) / _reserve0, (amount1 * _totalSupply) / _reserve1);
        }

        require(liquidity > 0, "UniswapV2:Insufficient_Liquidity_Minted");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);

        if (feeOn) {
            kLast = uint256(reserve0) * uint256(reserve1);
        }
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;

        require(amount0 > 0 && amount1 > 0, "UniswapV2:INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);

        uint256 balance0After = IERC20(token0).balanceOf(address(this));
        uint256 balance1After = IERC20(token1).balanceOf(address(this));

        _update(balance0After, balance1After, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * uint256(reserve1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, "UniswapV2:INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "UniswapV2:INSUFFICIENT_LIQUIDITY");

        require(to != token0 && to != token1, "UniswapV2:INVALID_TO");

        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);

        if (data.length > 0) {
            IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        }
        
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0In = 0;
        uint256 amount1In = 0;

        if (balance0 > _reserve0 - amount0Out) {
            amount0In  = balance0 - (_reserve0 - amount0Out);
        }
        if (balance1 > _reserve1 - amount1Out) {
            amount1In = balance1 - (_reserve1 - amount1Out);
        }

        require(amount0In > 0 || amount1In > 0, "UniswapV2:INSUFFICIENT_INPUT_AMOUNT");

        unchecked {
            uint256 balance0Adjusted = balance0 * 1000 - amount0In * 3;
            uint256 balance1Adjusted = balance1 * 1000 - amount1In * 3;

            require(
                balance0Adjusted * balance1Adjusted >= uint256(_reserve0) * uint256(_reserve1) * (1000 ** 2), "UniswapV2:K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, to);
    }

    function skim(address to) external override {
        address _token0 = token0;
        address _token1 = token1;

        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    function sync() external override {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }
}