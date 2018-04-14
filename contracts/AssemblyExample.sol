pragma solidity ^0.4.21;

contract Called {
    uint public n;
    function updateN (uint256 _n) public returns (uint256) {
        n = _n;
        return n;
    }
}

// delegatecall can't modify storage of called contract
// delegatecall allows called contract to modify storage of caller contract
contract Adder {
    uint public n;
    function sum(uint256 _a, uint256 _b) public returns (uint256) {
        n = _a + _b;
        return n;
    }
}

contract AssemblyExample {
  
    uint256 public n;
    
    function delegateCallAdder(address _addr, uint256 _a, uint256 _b) public returns (uint) {
        
        //Adder a = Adder(_addr);
        //address addr = address(a);
        bytes4 sig = bytes4(keccak256("sum(uint256,uint256)")); // function signature
        uint ans;
        
        assembly {
            // free memory pointer : 0x40
            
            let x := mload(0x40) // get empty storage location
            mstore ( x, sig ) // 4 bytes - place signature in empty storage
            mstore (add(x, 0x04), _a) // 32 bytes - place first argument next to 4-bit signature
            mstore (add(x, 0x24), _b) // 32 bytes - place second argument after first argument
            
            let ret := delegatecall(gas, 
                _addr,
                x, // input
                0x44, // input size = 32 + 32 + 4 bytes
                x, // output stored at input location, save space
                0x20 // output size = 32 bytes
            )
                
            ans := mload(x)
            mstore(0x40, add(x,0x20)) // update free memory pointer
        }
        
        uint256 n = ans;
        return n;
    }
    
    function callAdder(address _addr, uint256 _a, uint256 _b) public returns (uint ans) {
        //Adder a = Adder(_addr);
        //address addr = address(a);
        bytes4 sig = bytes4(keccak256("sum(uint256,uint256)")); // function signature
        
        assembly {
            // free memory pointer : 0x40
            
            let x := mload(0x40) // get empty storage location
            mstore ( x, sig ) // 4 bytes - place signature in empty storage
            mstore (add(x, 0x04), _a) // 32 bytes - place first argument next to 4-bit signature
            mstore (add(x, 0x24), _b) // 32 bytes - place second argument after first argument
            
            let ret := call (gas, 
                _addr,
                0, // no wei value passed to function
                x, // input
                0x44, // input size = 32 + 32 + 4 bytes
                x, // output stored at input location, save space
                0x20 // output size = 32 bytes
            )
                
            ans := mload(x)
            mstore(0x40, add(x,0x20)) // update free memory pointer
        }
    }
    
    function callUpdateN(address _addr, uint _n) public returns (uint ans) {
        Called c = Called(_addr);
        address addr = address(c);
        bytes4 sig = bytes4(keccak256("updateN(uint256)")); // function signature
        
        assembly {
            // free memory pointer : 0x40
            
            let x := mload(0x40) // get empty storage location
            mstore ( x, sig ) // 4 bytes
            mstore (add(x, 0x04), _n) // 32 bytes -  place argument next to 4-bit signature
            
            let ret := call (gas, 
                addr,
                0, // no value
                x, // input
                0x24, // input size = 32 + 4 bytes
                x,
                0x20)
                
            ans := mload(x)
            mstore(0x40, add(x,0x20)) // update free memory pointer
            
        }
    }
}

