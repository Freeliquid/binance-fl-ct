pragma solidity ^0.5.0;

contract PancakeStableStub {
    uint256 public decimals = 6;
}

contract PancakePairUSDTUSDCStub {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);

    string public name = "CAKE-LP";
    string public symbol = "CAKE-LP";
    uint256 public decimals = 18;
    uint256 _supply;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _approvals;

    PancakeStableStub t0;
    PancakeStableStub t1;

    constructor(uint256 supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;

        t1 = new PancakeStableStub();
        t0 = new PancakeStableStub();
    }

    function token0() public view returns (address) {
        return address(t0);
    }

    function token1() public view returns (address) {
        return address(t1);
    }

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        )
    {
        return (uint112(_supply), uint112(_supply), 0);
    }

    function totalSupply() public view returns (uint256) {
        return _supply;
    }

    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }

    function allowance(address src, address guy) public view returns (uint256) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        if (src != msg.sender) {
            require(_approvals[src][msg.sender] >= wad, "insufficient-approval");
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        require(_balances[src] >= wad, "insufficient-balance");
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }
}
