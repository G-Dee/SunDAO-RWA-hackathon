// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
//initial address 0xf53f27da838dc9d9dba474a08e1c6c8aa24d811e
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract SunDao is ERC20, ERC20Burnable, ERC20Pausable, AccessControl, ERC20Permit {
    mapping (address => uint256) public deposits;
    uint256 public totalDeposits;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    IERC20 stableToken = IERC20(0x435bA31fEA5F67D915053ddCaeE187Dee1fC7ea8);

    constructor(address defaultAdmin, address pauser)
        ERC20("SunDao", "SND")
        ERC20Permit("SunDao")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, pauser);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function depositToMint(uint256 stableTokenAmount) public {
        bool approveSuccess = stableToken.approve(address(this), stableTokenAmount);
        require(approveSuccess, "approval failed");
        bool transferSuccess = stableToken.transferFrom(msg.sender, address(this), stableTokenAmount);
        require(transferSuccess, "transfer failed");


        address to = msg.sender;
        uint256 amount = getMintAmount(stableTokenAmount);
        

        _mint(to, amount);

        deposits[msg.sender] += amount;
        totalDeposits += amount;
    }

    function withdrawToSeller(uint256 amount, address seller) public onlyRole(DEFAULT_ADMIN_ROLE){
        bool isApproveSuccess = stableToken.approve(msg.sender, amount);
        require(isApproveSuccess, "Token approval failed");
        bool isTransferSuccess = stableToken.transferFrom(address(this), seller, amount);
        require(isTransferSuccess);
    }


    function getMintAmount(uint256 amount) public view returns(uint256) {
        uint256 mintAmount;
        uint256 _totalSupply = totalSupply();
        
        if(totalDeposits == 0 && _totalSupply == 0){
            mintAmount = amount;
        } else{
            uint mintRatio = totalDeposits / _totalSupply;
            mintAmount = amount * mintRatio;
        }
        return mintAmount;
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}