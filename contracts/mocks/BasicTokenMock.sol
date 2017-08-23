pragma solidity 0.4.13;

import "../../contracts/Vitoken.sol";

contract BasicTokenMock is BasicToken
{
    function BasicTokenMock(address initialAddr, uint256 initialBalance)
    {
        balances[initialAddr] = initialBalance;
        totalSupply = initialBalance;
    }
}
