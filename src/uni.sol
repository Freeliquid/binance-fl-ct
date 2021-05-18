pragma solidity ^0.5.0;

import "./base.sol";
import "./safeMath.sol";

interface PancakeV2PairLike {
    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

/**
 * @title Adapter class needed to calculate USD value of specific amount of LP tokens
 * this contract assumes that USD value of each part of LP pair is eq 1 USD
 */
contract PancakeAdapterForStables is IAdapter {
    using SafeMath for uint256;

    struct TokenPair {
        address t0;
        address t1;
        uint256 r0;
        uint256 r1;
        uint256 usdPrec;
    }

    function calc(
        address gem,
        uint256 value,
        uint256 factor
    ) external view returns (uint256) {
        (uint112 _reserve0, uint112 _reserve1, ) = PancakeV2PairLike(gem).getReserves();

        TokenPair memory tokenPair;
        tokenPair.usdPrec = 10**6;

        tokenPair.t0 = PancakeV2PairLike(gem).token0();
        tokenPair.t1 = PancakeV2PairLike(gem).token1();

        tokenPair.r0 = uint256(_reserve0).mul(tokenPair.usdPrec).div(
            uint256(10)**IERC20(tokenPair.t0).decimals()
        );
        tokenPair.r1 = uint256(_reserve1).mul(tokenPair.usdPrec).div(
            uint256(10)**IERC20(tokenPair.t1).decimals()
        );

        uint256 totalValue = tokenPair.r0.min(tokenPair.r1).mul(2); //total value in uni's reserves for stables only

        uint256 supply = PancakeV2PairLike(gem).totalSupply();

        return value.mul(totalValue).mul(factor).mul(1e18).div(supply.mul(tokenPair.usdPrec));
    }
}


/**
 * @title Adapter class needed to calculate USD value of specific amount of LP tokens
 * this contract assumes that USD value of only one part of LP pair is eq 1 USD
 */
contract PancakeAdapterWithOneStable is IAdapter {
    using SafeMath for uint256;

    struct LocalVars {
        address t0;
        address t1;
        uint256 totalValue;
        uint256 supply;
        uint256 usdPrec;
    }

    address public deployer;
    address public buck;

    constructor() public {
        deployer = msg.sender;
    }

    function setup(address _buck) public {
        require(deployer == msg.sender);
        buck = _buck;
        deployer = address(0);
    }

    function calc(
        address gem,
        uint256 value,
        uint256 factor
    ) external view returns (uint256) {
        (uint112 _reserve0, uint112 _reserve1, ) = PancakeV2PairLike(gem).getReserves();

        LocalVars memory loc;
        loc.t0 = PancakeV2PairLike(gem).token0();
        loc.t1 = PancakeV2PairLike(gem).token1();
        loc.usdPrec = 10**6;

        if (buck == loc.t0) {
            loc.totalValue = uint256(_reserve0).mul(loc.usdPrec).div(
                uint256(10)**IERC20(loc.t0).decimals()
            );
        } else if (buck == loc.t1) {
            loc.totalValue = uint256(_reserve1).mul(loc.usdPrec).div(
                uint256(10)**IERC20(loc.t1).decimals()
            );
        } else {
            require(false, "gem w/o buck");
        }

        loc.supply = PancakeV2PairLike(gem).totalSupply();

        return
            value.mul(loc.totalValue).mul(2).mul(factor).mul(1e18).div(
                loc.supply.mul(loc.usdPrec)
            );
    }
}
