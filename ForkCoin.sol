///A token type which allows the issuing and burning of tokens by a

import "Token.sol";

contract ForkToken is Token{

    //sets the token creator as its factory
    function ForkToken(){
        owner = forkFuture(msg.sender);
    }
    ///Creates new coins out of thin air when called by the forkFuture contract
    function issue(address _recip, uint amount){
        if (msg.sender != address(owner)) return;
        balances[_recip] += amount;
    }
    //burns tokens to reclaim ether - only works if the fork period has passed
    function burn(uint _amount){
        if (balances[msg.sender] < _amount) return;
        balances[msg.sender] -= _amount;
        if (owner.returnEther(_amount, msg.sender) == false) throw;
    }
    forkFuture owner;
}

/// A futures contract which issues two tokens when funded with ether and only refunds 
/// the 'winning' token after a certain date.
contract forkFuture {

    //Creates two token contracts one for either a fork or no fork.
    function forkFuture(){
        noFork = new ForkToken();
        fork = new ForkToken();
    }
    // issues noFork and fork tokens equal to the value of the ether deposited
    function issue(){
        noFork.issue(msg.sender,msg.value);
        fork.issue(msg.sender,msg.value);
    }
    // Get the code at a particular address. Code provided by @chriseth.
    // Review carefully.
    function at(address _addr) returns (bytes o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }
    ///checks if the fork has happened and if it has sets the bool forked to true
    function setFork() {
        if (
            // Check that TheDAO's code has been changed...
            sha3(at(0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413)) != 0x7278d050619a624f84f51987149ddb439cdaadfba5966f7cfaea7ad44340a4ba
            ) 
        {forked = true;}
    }
    ///returns ether if called by the correct 'winning' token contract
    function returnEther(uint _amount, address _recip) returns (bool){
        //is past a certain date
        if (block.number < 1900000) return false;
        if (forked == true && msg.sender == address(fork))
        {
            _recip.send(_amount);
            return true;
        }
        else if (forked == false && msg.sender == address(noFork))
        {
            _recip.send(_amount);
            return true;
        }
        else return false;
    }
    
    bool forked;
    ForkToken noFork;
    ForkToken fork;
}