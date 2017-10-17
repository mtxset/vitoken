pragma solidity 0.4.15;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0)); 
    owner = newOwner;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) returns (bool) {

    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract ViMarket is StandardToken, Ownable
{
    // Token Infromation
    string public name = "Vitoken";
    string public symbol = "VIT";

    uint public decimals = 2;
    bool public allowBuying = true;

    uint private initialSupply = 9.999 * 10**(9+2); // 9.999 Billions + 2 decimal places

    uint public rate = 340; // 1$ - per token (use ether price in dollars)
    
    // All stages of sale
    enum Stages
    {
        Setup,
        PreICOFirstWeek,
        PreICOSecondWeek,
        PreICOThirdWeek,
        PreICOFourthWeek,
        ICO,
        End
    }
    Stages public Stage;

    // Dates for ICO sub-stages
    uint public constant PreICOSubStageStart = 1509926400; // Monday, 06-Nov-17 00:00:00 UTC
    uint public constant PreICOSubStageEnd = 1512000000; // Thursday, 30-Nov-17 00:00:00 UTC

    uint public constant ICOSubStageStart = 1512086400; // Friday, 01-Dec-17 00:00:00 UTC
    uint public constant ICOSubStageEnd = 1514678400;  // Sunday, 31-Dec-17 00:00:00 UTC

    // Limits for tokens
    uint public constant PreICOSubStageTokenLimit = 100 * 10**6; // 100 Millions
    uint public constant ICOSubStageTokenLimit = 50 * 10**6; // 50 Millions

    // Prices 
    //  100 % - rate
    //    x % - rateX
    uint256 public PreICOFirstWeekRate = 40 * rate / 100; // 0.4 $/token
    uint256 public PreICOSecondWeekRate = 50 * rate / 100; // 0.5 $/token
    uint256 public PreICOThirdWeekRate = 60 * rate / 100; // 0.6 $/token
    uint256 public PreICOFourthWeekRate = 70 * rate / 100; // 0.7 $/token
    uint256 public ICORate = 75 * rate / 100; // 75 %

    // Fallback function and Constructor
    function () payable 
    {
        BuyTokens(msg.sender);
    }
    
    function ViMarket()
    {
        owner = msg.sender;
        balances[owner] = initialSupply;
        totalSupply = initialSupply;
        
        Stage = Stages.Setup;
    }
    // -- Fallback function and Constructor
    
    // Contract functions
    function transferOwnership(address newOwner) 
    onlyOwner
    {
        address oldOwner = owner;
        super.transferOwnership(newOwner);
        EventOwnerTransfered(oldOwner, newOwner);
    }

    function BuyTokens(address beneficiary) 
    payable 
    {
        require(Stage != Stages.Setup);
        require(Stage != Stages.End);
        require(beneficiary != 0x0);
        require(beneficiary != owner);
        require(msg.value > 0);

        uint weiAmount = msg.value;
        uint etherAmount = WeiToEther(weiAmount);
        
        uint tokens = etherAmount.mul(GetCurrentRate());

        balances[beneficiary] = balances[beneficiary].add(tokens);
        balances[owner] = balances[owner].sub(tokens);

        EventTokenPurchase(msg.sender, beneficiary, etherAmount, tokens, rate);
    }
    // Rate function - returns rate by checking current Stage
    function GetCurrentRate() public constant
    returns (uint)
    {
        Stages currentStage = GetCurrentStage();
        if (currentStage == Stages.PreICOFirstWeek)
            return PreICOFirstWeekRate;

        if (currentStage == Stages.PreICOSecondWeek)
            return PreICOSecondWeekRate;

        if (currentStage == Stages.PreICOThirdWeek)
            return PreICOThirdWeekRate;

        if (currentStage == Stages.PreICOFourthWeek)
            return PreICOFourthWeekRate;

        if (currentStage == Stages.ICO)
            return ICORate;
    }

    // Stage functions
    function GetCurrentStage() public constant
    returns (Stages)
    {
        if (now >= PreICOSubStageStart && now <= PreICOSubStageEnd)
        {
            if (now >= PreICOSubStageStart + 1 weeks && now <= PreICOSubStageStart + 2 weeks)
                return Stages.PreICOFirstWeek;
            else if (now >= PreICOSubStageStart + 2 weeks && now <= PreICOSubStageStart + 3 weeks)
                return Stages.PreICOSecondWeek;
            else if (now >= PreICOSubStageStart + 3 weeks && now <= PreICOSubStageStart + 4 weeks)
                return Stages.PreICOThirdWeek;
            else if (now >= PreICOSubStageStart + 4 weeks && now <= PreICOSubStageStart + 5 weeks)
                return Stages.PreICOFourthWeek;
        }
        else if (now >= ICOSubStageStart && now <= ICOSubStageEnd)
            return Stages.ICO;
    }

    function ChangeState(Stages stage) public
    onlyOwner
    {
        if (stage == Stages.PreICOFirstWeek && Stage == Stages.Setup)
            { Stage = stage; return; }
        else if (stage == Stages.PreICOSecondWeek && Stage == Stages.PreICOFirstWeek)
            { Stage = stage; return; }
        else if (stage == Stages.PreICOThirdWeek && Stage == Stages.PreICOSecondWeek)
            { Stage = stage; return; }
        else if (stage == Stages.PreICOFourthWeek && Stage == Stages.PreICOThirdWeek)
            { Stage = stage; return; }
        else if (stage == Stages.ICO && Stage == Stages.PreICOFourthWeek)
            { Stage = stage; return; }
    }

    function RetrieveFunds()
    onlyOwner
    {
        owner.transfer(this.balance);
    }

    function Destroy()
    onlyOwner
    {
        selfdestruct(owner);
    }
    // -- Contract functions
    
    // Helper functions
    function WeiToEther(uint v) internal 
    returns (uint)
    {
        require(v > 0);
        return v.div(1 ether);
    }

    function EtherToWei(uint v) internal
    returns (uint)
    {
      require(v > 0);
      return v.mul(1 ether);
    }

    // Events
    event EventOwnerTransfered(address oldOwner, address newOwner);

    event EventRateChanged(uint oldRate, uint newRate);

    event EventTokenPurchase(
    address indexed purchaser, 
    address indexed beneficiary, 
    uint256 amountInEther, 
    uint256 tokens,
    uint buyRate);
    // --
}