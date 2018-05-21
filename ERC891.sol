pragma solidity ^ 0.4.23;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract EIP20Interface {
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract EIP20 is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public name;                   
    uint8 public decimals;                
    string public symbol;                 

    function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;               
        totalSupply = _initialAmount;                        
        name = _tokenName;                                   
        decimals = _decimalUnits;                            
        symbol = _tokenSymbol;                               
    }
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}



contract ERC891 is Ownable, EIP20 {
    
    // Events 
  event Mine(address indexed to, uint256 amount);
  event MiningFinished();


    // Settings
  bool public miningFinished = false;
  uint256 public fee;
  uint256 diffMask = 3;
  uint256 bitpool = 52;
  uint256 stepLength = 142857;
  
  
    // State
  uint256 b0;
  uint256 bn = 0;
  uint256 step = 1;
  
  
    // Reward Steps
  mapping(uint256 => uint256) rewardSteps;


    // Collection Database
  mapping(address => bool) claimed;


  modifier canMine {
    require(!miningFinished);
    _;
  }


    /* -----------------------------------------------------
        claim() 
        
        - Realizes the balance of the address.
        - Requires to have an unclaimed property.
        - The claimed value should be in the mapping 
        i.e. not error 9000
        
        reward          <- item ID from checkFind(sender)

        
    ----------------------------------------------------- */

  function claim() canMine public {
    require(!claimed[msg.sender]);

    if(block.number - b0 > stepLength * step) step++;
    uint256 reward = checkFind(msg.sender);
   
    require(reward != 9000);

    
    claimed[msg.sender] = true;
    balances[msg.sender] = balances[msg.sender] + reward;
    
    emit Mine(msg.sender, reward);
  }

    /* -----------------------------------------------------
        checkFind(address) returns (uint16)
        
        - Checks the reward for address.
        - Zero returning is not possible. Connected to
        the wrong network or error.
        - Returning 9000 signals an invalid address for
        the current difficulty mask.
        
        dataSelector    <- address 160 bits
        data            <- address masked to bitpool bits
        bitCount        <- store the 1 bit count in data

        
        Apply the diff mask by cheking the single case 
        2^(diffMask)-1 AND the first bits of the address
        which needs to be 0.
        
    ----------------------------------------------------- */

  function checkFind(address _address) view public returns(uint256) {
    uint8  bitCount = 0;
    
    bytes20 data = bytes20(_address) & bytes20((1 << bitpool) - 1); 

    while (data != 0) {
      bitCount = bitCount + uint8(data & 1);
      data = data >> 1;
    }

    return rewardSteps[stepLength*step];
  }

}



contract Ore is ERC891 {
 /*  ------------------- 
    2.08480398073
    0.465798371432
    0.272238277047
    0.190886928436
    0.146059605391
    0.117732926945
    0.0982583820002
 ------------------- */

  constructor(uint256 _fee) public {
    fee = _fee * 1000000000000; // 0.001 finney
    
    rewardSteps[stepLength*1] = 2084803980730000000;
    rewardSteps[stepLength*2] = 465798371432000000;
    rewardSteps[stepLength*3] = 272238277047000000;
    rewardSteps[stepLength*4] = 190886928436000000;
    rewardSteps[stepLength*5] = 146059605391000000;
    rewardSteps[stepLength*6] = 117732926945000000;
    rewardSteps[stepLength*7] = 98258382000200000;
    
    b0 = block.number;

  }

  function setFee(uint256 _fee) onlyOwner public {
    fee = _fee * 1000000000000;
  }
  
  function setDifficulty(uint256 _diffMask) public {
    diffMask = _diffMask;
  }
}
