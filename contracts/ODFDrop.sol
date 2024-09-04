// SPDX-License-Identifier: MIT

/*

██████╗ ███████╗██╗███╗   ██╗███████╗██╗  ██╗    ██████╗ ██████╗  ██████╗ ████████╗ ██████╗  ██████╗ ██████╗ ██╗     
██╔══██╗██╔════╝██║████╗  ██║██╔════╝╚██╗██╔╝    ██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔═══██╗██╔════╝██╔═══██╗██║     
██║  ██║█████╗  ██║██╔██╗ ██║█████╗   ╚███╔╝     ██████╔╝██████╔╝██║   ██║   ██║   ██║   ██║██║     ██║   ██║██║     
██║  ██║██╔══╝  ██║██║╚██╗██║██╔══╝   ██╔██╗     ██╔═══╝ ██╔══██╗██║   ██║   ██║   ██║   ██║██║     ██║   ██║██║     
██████╔╝██║     ██║██║ ╚████║███████╗██╔╝ ██╗    ██║     ██║  ██║╚██████╔╝   ██║   ╚██████╔╝╚██████╗╚██████╔╝███████╗
╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝

-------------------------------------------- odfdrop.space ------------------------------------------------------------

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ODFAirDropV1 is Ownable {
    using SafeMath for uint256;
    
    // Use of SafeERC20 for the IERC20 interface for safe handling of ERC20 tokens.
    using SafeERC20 for IERC20;

    // Private field to store the address of the reward token contract.
    IERC20 private rewardToken;

    // Public field to bonus for inviting
    uint256 public pointBonus;

    // Public field to store the total number of tasks.
    uint256 public totalTasks;

    // Description of the task structure, which contains a description, points, and completion flag.
    struct Task {
        string description;
        uint256 price;
        bool completed;
        address participant;
    }

    // Mapping to store tasks by their identifier.
    mapping(uint256 => Task) public tasks;

    // Public field to store the total number of users.
    address[] private totalUsers;

    // Description of the usert structure, which contains a completed, participant, and point balance, refferals.
    struct User {
        uint256 points;
        mapping(address => bool) referrals;
        mapping(uint256 => bool) tasks;
    }

    // Private mapping to store users.
    mapping(address => User) private users;

    // Event for adding a new task.
    event TaskAdded(uint256 taskId, string description, uint256 points);

    // Event for completing a task and earning points.
    event TaskCompleted(uint256 taskId, address participant, uint256 pointsEarned);

    event ReferralReward(address indexed referrerAddress, address indexed refereeAddress);

    // Constructor of the contract that takes the reward token address and calls the Ownable constructor with the owner's address.
    constructor() Ownable(msg.sender) {
        pointBonus = 100;

        rewardToken = IERC20(0x2Ec1c429385Bd6175A8758012A43B2eB211710C4);
    }

    // Distribution of tokens among participants depending on their points balance
    function distributeTokens() external onlyOwner {
        uint256 totalUsersPoins = 0;
        for (uint256 i = 0; i < totalUsers.length; i++) {
            totalUsersPoins += users[totalUsers[i]].points;
        }

        require(totalUsersPoins > 0, "Drop: total points should be greater than 0");

        uint256 totalTokens = rewardToken.balanceOf(address(this));

        uint256 remainingTokens = totalTokens;

        for (uint256 i = 0; i < totalUsersPoins; i++) {
            User storage user = users[totalUsers[i]];

            if (user.points > 0) {
                uint256 tokensToDistribute = user.points.mul(totalTokens).div(totalUsersPoins);

                if (tokensToDistribute > 0) {
                    rewardToken.safeTransfer(totalUsers[i], tokensToDistribute);
                    
                    user.points = user.points.add(user.points);

                    emit TaskCompleted(i, totalUsers[i], user.points);
                }
            }
        }

        if (remainingTokens > 0) {
            rewardToken.safeTransfer(owner(), remainingTokens);
        }
    }

    // Function to complete a task, which increases the participant's points balance.
    function completeTask(uint256 _taskId, address _referrer) external {
        require(_taskId > 0 && _taskId <= totalTasks, "Drop: invalid task ID");

        Task storage task = tasks[_taskId];

        require(!users[msg.sender].tasks[_taskId], "Drop: task already completed");

        users[msg.sender].tasks[_taskId] = true;

        users[msg.sender].points += task.price;

        if (!isAddressInList(msg.sender)) {
            totalUsers.push(msg.sender);
        }

        if (_referrer != address(0) && !users[_referrer].referrals[msg.sender]) {
            users[_referrer].referrals[msg.sender] = true;

            users[_referrer].points += pointBonus;
        }

        emit TaskCompleted(_taskId, msg.sender, task.price);
    }

    // Function to add a new task by the contract owner.
    function addTask(string memory _description, uint256 _points) external onlyOwner {
        totalTasks++;
        tasks[totalTasks] = Task(_description, _points, false, address(0));

        emit TaskAdded(totalTasks, _description, _points);
    }

    // Function to update bonus percentage
    function setPointBonus(uint256 _bonus) external onlyOwner {
        pointBonus = _bonus;
    }

    // Function to fetch the completed task.
    function fetchCompletedTask(uint256 _taskId) external view returns (bool) {
       return users[msg.sender].tasks[_taskId];
    }

    // Function to fetch the point balance of a specific address.
    function fetchPointBalance(address _address) external view returns (uint256) {
        return users[_address].points;
    }

    // Function to fetch the point balance of the calling address.
    function fetchMyPointBalance() external view returns (uint256) {
        return users[msg.sender].points;
    }

    // Function for emergency withdrawal of tokens from the contract by the owner.
    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    // Function for emergency withdrawal of ETH from the contract by the owner.
    function emergencyWithdrawETH(uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount);
    }

    // Function to check if an address is in the list
    function isAddressInList(address _address) private view returns (bool) {
        for (uint i = 0; i < totalUsers.length; i++) {
            if (totalUsers[i] == _address) {
                return true;
            }
        }
        return false;
    }

}
