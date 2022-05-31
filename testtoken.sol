pragma solidity>0.8.0;//SPDX-License-Identifier:None
import"https://github.com/aloycwl/ERC_AC/blob/main/ERC20AC/ERC20AC.sol";
contract ERC20AC_93N is ERC20AC{
    constructor(){
        _totalSupply=102e21;
        _balances[msg.sender]=_totalSupply;
        emit Transfer(address(this),msg.sender,_totalSupply);
    }
    function name()external pure override returns(string memory){return"93N Token";}
    function symbol()external pure override returns(string memory){return"93N";}
}