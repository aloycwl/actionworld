pragma solidity>0.8.0;//SPDX-License-Identifier:None

interface AWToken{function transfer(address,uint)external;}

contract BulkSend{
    AWToken private ierc20;
    constructor(address a){
        ierc20 = AWToken(a);
    }
}