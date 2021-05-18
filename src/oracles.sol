pragma solidity ^0.5.0;

import "./uni.sol";
import "./safeMath.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}


/**
 * @title oracle for Pancake LP tokens which contains stable coins
 * this contract assume no USDT tokens in pair
 * both of stables assumed 1 USD
 *
*/
contract PancakeAdapterPriceOracle_Buck_Buck {
    using SafeMath for uint256;

    struct TokenPair {
        address t0;
        address t1;
    }

    PancakeV2PairLike public gem;
    address public deployer;

    constructor() public {
        deployer = msg.sender;
    }

    /**
     * @dev initialize oracle
     * _gem - address of PancakePair contract
     */
    function setup(address _gem) public {
        require(deployer == msg.sender);
        gem = PancakeV2PairLike(_gem);
        deployer = address(0);
    }

    /**
     * @dev calculate price
     */
    function calc() internal view returns (bytes32, bool) {
        (uint112 _reserve0, uint112 _reserve1, ) = gem.getReserves();

        TokenPair memory tokenPair;
        tokenPair.t0 = gem.token0();
        tokenPair.t1 = gem.token1();

        uint256 usdPrec = 10**6;

        uint256 r0 =
            uint256(_reserve0).mul(usdPrec).div(
                uint256(10)**uint256(IERC20(tokenPair.t0).decimals())
            );
        uint256 r1 =
            uint256(_reserve1).mul(usdPrec).div(
                uint256(10)**uint256(IERC20(tokenPair.t1).decimals())
            );

        //we use the minimum USD value of the two tokens to prevent Pancake disbalance attack
        uint256 totalValue = r0.min(r1).mul(2); //total value in uni's reserves
        uint256 supply = gem.totalSupply();

        return (
            bytes32(
                totalValue.mul(10**(uint256(gem.decimals()).add(18))).div(supply.mul(usdPrec))
            ),
            true
        );
    }

    /**
     * @dev base oracle interface see OSM docs
     */
    function peek() public view returns (bytes32, bool) {
        return calc();
    }

    /**
     * @dev base oracle interface see OSM docs
     */
    function read() public view returns (bytes32) {
        bytes32 wut;
        bool haz;
        (wut, haz) = calc();
        require(haz, "haz-not");
        return wut;
    }
}
