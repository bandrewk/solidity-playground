//SPDX-License-Identifier: AGPL-3.0-or-later
// @bandrewk 10.06.2021

pragma solidity ^0.8.4;


/**************************************************************
 * 
 *  User object
 * 
 **************************************************************/
struct User
{
    bool    m_bEnabled; // Is user allowed to withdraw? 
    uint    m_iWithdrawCountLimitPerDay; // Max. Number of transactions per day
    uint    m_iWithdrawLimit; // Max. amount to withdraw in a single run
    uint    m_iWithdrawsAvailable;
    Wallet  m_wWallet; // User's wallet
}

/**************************************************************
 * 
 *  Transaction object
 * 
 **************************************************************/
enum TransactionType
{
    WITHDRAW,
    DEPOSIT,
    ADMIN
}
    
// Single transaction
struct Transaction 
{
    uint    m_iAmount;  // Transaction amount
    uint    m_iTimeStamp; // Transaction timestamp
    TransactionType m_eType; // Transaction type
}

/**************************************************************
 * 
 *  User Wallet object
 * 
 **************************************************************/
struct Wallet
{
    uint     m_iTotalBalance ; // Wallet's current balance >= 0
    uint     m_iTransactionId; // Current transaction id
    mapping(uint => Transaction)  m_mTransaction; // Transaction history
}
