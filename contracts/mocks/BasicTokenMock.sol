pragma solidity 0.4.15;

import "../../contracts/Vitoken.sol";

contract BasicTokenMock is BasicToken
{
    function BasicTokenMock(address initialAddr, uint256 initialBalance)
    {
        balances[initialAddr] = initialBalance;
        totalSupply = initialBalance;
    }
}
