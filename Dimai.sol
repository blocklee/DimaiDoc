// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//  import "@openzeppelin/contracts/access/Ownable.sol";
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//  本合约删除了标准库 renounceOwnership() 函数，该合约涉及到资金提取不能丢弃所有者权限
//  本合约设置了初始费用单价，合约销毁功能，余额提款功能，向指定地址打款功能，费用设置功能，使用付费功能
contract Dimai is Ownable {
    using SafeMath for uint256;

    // 设置初始费用 0.01 meer
    uint256 public feeUnit = 0.01 ether;

    // 设置用户使用Dimai绘图事件
    event UseDimai(address indexed User, uint256 Cost);

    // 设置收款事件
    event Received(address indexed Sender, uint Amount);


    function destroyContract() public onlyOwner {
        //检查是否为合约所有者，不是就报错了
        //在自毁合约前必须把合约内的代币（指二层token；selfdestruct()本身就是转走eth）转走
        //        payable(msg.sender).transfer(address(this).balance);
        selfdestruct(payable(msg.sender));
    }

    // 提取所有余额
    function withdrawAll() public onlyOwner {
        //检查是否为合约所有者，不是就报错了
        //提取所有余额
        payable(msg.sender).transfer(address(this).balance);
    }

    // 批量分发余额
    function sendToC(
        address payable[] memory to,
        uint256[] memory amount
    ) public onlyOwner {
        // 只有 owner 才可以调用分发余额函数
        uint256 length = to.length;
        require(to.length == amount.length, "Transfer length error");
        uint256 allAmount;
        for (uint256 i = 0; i < length; i++) {
            allAmount += amount[i];
        }
        require(address(this).balance >= allAmount, "Transfer amount is over the limit");
        for (uint256 i = 0; i < length; i++) {
            payable(to[i]).transfer(amount[i]);
        }
    }

    function setFee(uint256 _fee) public isOwner {
        feeUnit = _fee;
    }

    function useDimai(uint256 times) public {
        // times 为调用绘图需要叠加的计费倍率，由前端计算计费倍率
        uint256 totalFee = feeUnit.mul(times);
        require(msg.value == totalFee, "Incorrect fee amount");
        // use dimai, pay fee to owner
        payable(_owner).transfer(totalFee);

        emit UseDimai(msg.sender, msg.value);
    }

    // 增加 receive() 回调函数，合约可接收汇款，对于用户不能调用 Dimai 合约的情况，可让第三方直接打款到本合约地址
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

