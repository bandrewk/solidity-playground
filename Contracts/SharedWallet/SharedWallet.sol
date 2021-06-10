//SPDX-License-Identifier: AGPL-3.0-or-later
// @bandrewk 10.06.2021

pragma solidity ^0.8.4;

import "./Types.sol";

contract SharedWallet
{
    bool    m_bContractPaused; // Contract paused
    address m_aContractOwner; // Owner address
    uint public   m_iTotalBalance; // Keeps track of the total balance of the contract
    
    mapping(address => User) m_mUser;
    
    modifier ActiveOnly
    {
        require(!m_bContractPaused,"Contract is paused.");
        _;
    }
    
    constructor()
    {
        m_aContractOwner = msg.sender;
    }
    
    receive() payable external
    {
        // received payment fallback
        Deposit();
    }
    
    // Deposit money to contract 
    function Deposit() payable public
    {
        m_iTotalBalance += msg.value;
    }
    
    // Withdraw money
    function Withdraw(uint _amount) public ActiveOnly
    {
        if(msg.sender != m_aContractOwner)
        {
            // User withdraw
            require(m_mUser[msg.sender].m_bEnabled, "Account suspended.");
            require(CanUserWithdraw(), "Daily withdraw count limit reached.");
            require(IsTransactionWithinLimits(_amount), "Transaction amount too high.");

            // Withdraw from user balance
            UserWithdraw(_amount);
        }   
        
        // If we made it this far and the balances don't add up someting must be wrong!
        if(m_iTotalBalance < _amount)
        {
            m_bContractPaused = true;
            return;
        }
        else 
        {
            m_iTotalBalance -= _amount;
        
            payable(msg.sender).transfer(_amount);
        }
    }
    
    /**************************************************************
     * 
     *  User Wallet functions
     * 
     **************************************************************/
     
    // Check balance
    function CheckUserBalance() private view returns(uint)
    {
        return m_mUser[msg.sender].m_wWallet.m_iTotalBalance;
    }
    
    
    // Withdraw money
    function UserWithdraw(uint _amount) private 
    {
        require(m_mUser[msg.sender].m_wWallet.m_iTotalBalance >= _amount, "Insufficient funds");
        
        m_mUser[msg.sender].m_wWallet.m_iTotalBalance -= _amount;
        
        RunTransaction(_amount, TransactionType.WITHDRAW);
    }
    
    // Deposit money
    function UserDeposit(uint _amount) private 
    {
        m_mUser[msg.sender].m_wWallet.m_iTotalBalance += _amount;
        
        RunTransaction(_amount, TransactionType.DEPOSIT);
    }
    
    function LastTransactionDate() private view returns(uint) 
    {
        return m_mUser[msg.sender].m_wWallet.m_mTransaction[m_mUser[msg.sender].m_wWallet.m_iTransactionId].m_iTimeStamp;
    }
    
    // Helper function to run transactions
    function RunTransaction(uint _amount, TransactionType _type) private
    {
        m_mUser[msg.sender].m_wWallet.m_mTransaction[m_mUser[msg.sender].m_wWallet.m_iTransactionId].m_iAmount = _amount;
        m_mUser[msg.sender].m_wWallet.m_mTransaction[m_mUser[msg.sender].m_wWallet.m_iTransactionId].m_iTimeStamp = block.timestamp;
        m_mUser[msg.sender].m_wWallet.m_mTransaction[m_mUser[msg.sender].m_wWallet.m_iTransactionId].m_eType = _type;
        m_mUser[msg.sender].m_wWallet.m_iTransactionId++;
    }
    
    // Checks if a user is able to withdraw according to the set limits
    function CanUserWithdraw() private returns(bool)
    {
        if(LastTransactionDate() < block.timestamp - 1 days)
        {
            // Not the first transaction today, check limits
            if(m_mUser[msg.sender].m_iWithdrawsAvailable > 0)
            {
                // Go on
                m_mUser[msg.sender].m_iWithdrawsAvailable--;
                return true;
            }
            else return false;
        }
        else
        {
            // First transaction today
            // Reset any limits
            m_mUser[msg.sender].m_iWithdrawsAvailable = m_mUser[msg.sender].m_iWithdrawCountLimitPerDay;
            m_mUser[msg.sender].m_iWithdrawsAvailable--;
            
            return true;
        }
    }
    
    // Can user withdraw the amount requested?
    function IsTransactionWithinLimits(uint _amount) private view returns(bool)
    {
        if(m_mUser[msg.sender].m_iWithdrawLimit < _amount) return false;
        else return true;
        
    }
    
    /**************************************************************
     * 
     *  Management functionos -- Owner Only
     * 
     **************************************************************/
     
    modifier OwnerOnly
    {
        require(msg.sender == m_aContractOwner, "You are not the owner.");
        _;
    }
    
    modifier UserExistent (address _address)
    {
        require(m_mUser[_address].m_bEnabled, "User not existent.");
        _;
    }
    
    function AddUser(address _address, uint _budget, uint _withdrawCountLimitPerDay, uint _withdrawLimit) public OwnerOnly
    {
        require(!m_mUser[_address].m_bEnabled, "User already existent.");
        
        // Enable account
        m_mUser[_address].m_bEnabled = true;
        
        //Adjust Budget and limits
        ChangeUserBudget(_address, _budget);
        ChangeUserLimits(_address, _withdrawCountLimitPerDay, _withdrawLimit);
    }
    
    function ChangeUserBudget(address _address, uint _budget) public OwnerOnly UserExistent(_address)
    {
        m_mUser[_address].m_wWallet.m_iTotalBalance = _budget;

        RunTransaction(_budget, TransactionType.ADMIN);
    }
    
    function ChangeUserLimits(address _address, uint _withdrawCountLimitPerDay, uint _withdrawLimit) public OwnerOnly UserExistent(_address)
    {
        m_mUser[_address].m_iWithdrawCountLimitPerDay = _withdrawCountLimitPerDay;
        m_mUser[_address].m_iWithdrawsAvailable = _withdrawCountLimitPerDay;
        m_mUser[_address].m_iWithdrawLimit = _withdrawLimit;
    }
    
    function DeactivateUser(address _address) public OwnerOnly UserExistent(_address)
    {
        m_mUser[_address].m_bEnabled = false;
    }
    
    function PauseContract(bool _paused) public OwnerOnly
    {
        m_bContractPaused = _paused;
    }
    
    function SetOwner(address _address) public OwnerOnly
    {
        m_aContractOwner = _address;
    }
    
}
