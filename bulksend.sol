pragma solidity>0.8.0;//SPDX-License-Identifier:None

interface AWToken{function transferFrom(address,address,uint256)external;}

contract BulkSend{
    AWToken private awt;
    constructor(address a){
        awt = AWToken(a);
    }
    function send()external{
        address[3] memory addrs=[address(0),address(0),address(0)];
        for(uint i=0;i<addrs.length;i++)awt.transferFrom(0x15eD406870dB283E810D5885e432d315C94DD0dd,addrs[i],1e21);
    }
}