pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // using pure because it has a constant value
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external pure returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    // hash unique hash for the EIP-712 domain.
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    // keccak256(
    //     EIP712Domain(
    //         name = "Uniswap V2",
    //         version = "1",
    //         chainId = 1,
    //         verifyingContract = address(this);
    //     )
    // )

    // hash of the permit data structure
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    // permit(
    //     address owner,
    //     address spender,
    //     uint256 value,
    //     uint256 nonce,
    //     uint256 deadline
    // )

    // like a serial number
    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s   
    ) external;

}