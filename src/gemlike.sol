pragma solidity ^0.5.12;

import "./lib.sol";
import "./IERC20.sol";

interface VatLike {
    function slip(
        bytes32,
        address,
        int256
    ) external;

    function move(
        address,
        address,
        uint256
    ) external;
}

// For a token that does not return a bool on transfer or transferFrom (like OMG)
// This is one way of doing it. Check the balances before and after calling a transfer

contract GemJoinLP is LibNote {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike public vat;
    bytes32 public ilk;
    IERC20 public gem;
    uint256 public dec;
    uint256 public live;  // Access Flag

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = IERC20(gem_);
        dec = gem.decimals();
    }

    function cage() external note auth {
        live = 0;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "GemJoinLP/overflow");
    }

    function join(address urn, uint256 wad) public note {
        require(live == 1, "GemJoinLP/not-live");
        require(wad <= 2 ** 255, "GemJoinLP/overflow");
        vat.slip(ilk, urn, int256(wad));
        uint256 prevBalance = gem.balanceOf(msg.sender);

        require(prevBalance >= wad, "GemJoinLP/no-funds");
        require(gem.allowance(msg.sender, address(this)) >= wad, "GemJoinLP/no-allowance");

        (bool ok,) = address(gem).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), wad)
        );
        require(ok, "GemJoinLP/failed-transfer");

        require(prevBalance - wad == gem.balanceOf(msg.sender), "GemJoinLP/failed-transfer");
    }

    function exit(address guy, uint256 wad) public note {
        require(wad <= 2 ** 255, "GemJoinLP/overflow");
        vat.slip(ilk, msg.sender, -int256(wad));
        uint256 prevBalance = gem.balanceOf(address(this));

        require(prevBalance >= wad, "GemJoinLP/no-funds");

        (bool ok,) = address(gem).call(
            abi.encodeWithSignature("transfer(address,uint256)", guy, wad)
        );
        require(ok, "GemJoinLP/failed-transfer");

        require(prevBalance - wad == gem.balanceOf(address(this)), "GemJoinLP/failed-transfer");
    }
}
