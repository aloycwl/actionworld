pragma solidity>0.8.0;//SPDX-License-Identifier:None

interface AWToken{function transferFrom(address,address,uint256)external;}

contract BulkSend{
    AWToken private awt;
    constructor(address a){
        awt = AWToken(a);
    }
    function send()external{
        address a=address(0);
        uint b=1e21;
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);

        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);

        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);

        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);

        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);

        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);

        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);

        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);

        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);

        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
        awt.transferFrom(a,,b);
    }
}