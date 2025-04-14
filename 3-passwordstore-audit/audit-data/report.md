---
title: Protocol Audit Report
author: s3bc40
date: November 19, 2024
header-includes:
  - \usepackage{titling}
  - \usepackage{graphicx}
---

 \begin{titlepage}
 \centering
 {\Huge\bfseries Protocol Audit Report\par}
 \vspace{2cm}
 \begin{figure}[h]
 \centering
 \includegraphics[width=0.5\textwidth]{logo.pdf}
 \end{figure}
 \vspace{2cm}
 {\Large Version 1.0\par}
 \vspace{1cm}
 {\Large\itshape s3bc40\par}
 \vfill
 {\large \today\par}
 \end{titlepage}

\maketitle

<!-- Your report starts here! -->

Prepared by: [s3bc40](https://github.com/s3bc40)
Lead Security Researcher:

- s3bc40

# Table of Contents

- [Table of Contents](#table-of-contents)
- [Protocol Summary](#protocol-summary)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
  - [Roles6](#roles6)
- [Executive Summary](#executive-summary)
  - [Issues found](#issues-found)
- [Findings](#findings)
- [High](#high)
    - [\[H-1\] Variables stored in storage on-chain are visible to anyone, no matter the solidity visibility keyword. Meaning the password is not private](#h-1-variables-stored-in-storage-on-chain-are-visible-to-anyone-no-matter-the-solidity-visibility-keyword-meaning-the-password-is-not-private)
    - [\[H-2\] `PasswordStore::setPassword` has no access controls, meaning a non-owner could change the password](#h-2-passwordstoresetpassword-has-no-access-controls-meaning-a-non-owner-could-change-the-password)
- [Informational](#informational)
    - [\[I-1\] The `PasswordStore::getPassword` natspec indicates a parameter that doesn't exist, causing the natspec to be incorrect.](#i-1-the-passwordstoregetpassword-natspec-indicates-a-parameter-that-doesnt-exist-causing-the-natspec-to-be-incorrect)

# Protocol Summary

The PasswordStore smart contract is a decentralized application designed to allow users to securely store and retrieve passwords. The contract ensures that only the user who set the password can access it, preventing unauthorized access by others. This report evaluates the contract's functionality, security, and adherence to best practices.

# Disclaimer

The s3bc40 team makes all effort to find as many vulnerabilities in the code in the given time period, but holds no responsibilities for the findings provided in this document. A security audit by the team is not an endorsement of the underlying business or product. The audit was time-boxed and the review of the code was solely on the security aspects of the Solidity implementation of the contracts.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

We use the [CodeHawks](https://docs.codehawks.com/hawks-auditors/how-to-evaluate-a-finding-severity) severity matrix to determine severity. See the documentation for more details.

# Audit Details

**Commit Hash:**

```
2e8f81e263b3a9d18fab4fb5c46805ffc10a9990
```

## Scope

```
./src/
#-- PasswordStore.sol
```

## Roles6

- Owner: The user who can set the password and read the password.
- Outsiders: No one else should be able to set or read the password.

# Executive Summary

_How the audit went, things found etc._

_We spent X hours with Z and Y auditors using H tool. etc._

## Issues found

| Severity | Number of issues found |
| -------- | ---------------------- |
| High     | 2                      |
| Medium   | 0                      |
| Low      | 0                      |
| Info     | 1                      |
| Total    | 2                      |

# Findings

# High
### [H-1] Variables stored in storage on-chain are visible to anyone, no matter the solidity visibility keyword. Meaning the password is not private

**Description:** All data stored on-chain is visible to anyone, and can be read directly from the blockchain. The `PasswordStore::s_password` variable is intented to be a private variable and only accessed through the `PasswordStore::getPassword` method, intended to be called only by the owner.

**Impact:** Anyone can read the private password, severly breaking the functionality of the protocol.

**Proof of Concept (or Proof of code):** The below test case shows how anyone could read the password directly from the blockchain. We use foundry's cast tool to read directly from the storage of the contract, without being the owner.

1. Create a locally running chain

```bash
make anvil
```

2. Deploy the contract to the chain

```bash
make deploy
```

3. Run the storage tool

We use 1 because that's the storage slot of s_password in the contract.

```bash
cast storage <ADDRESS_HERE> 1 --rpc-url http://127.0.0.1:8545
```

You get the following password

```bash
myPassword
```

**Recommended Mitigation:** Due to this, the overall architecture of the contract should be rethought. One could encrypt the password off-chain, and then store the encrypted password on-chain. This would require the user to remember another password off-chain to decrypt the stored password. However, you're also likely want to remove the view function as you wouldn't want the user to accidentally send a transaction with this decryption key.

### [H-2] `PasswordStore::setPassword` has no access controls, meaning a non-owner could change the password

**Description:**

> (`PasswordStore::setPassword` is a function to set the private state variable `PasswordStore::s_password`. Right now only the owner can access to his password with the following getter `PasswordStore::setPassword`, so it is important to apply the same level of access control to set the user's password.) -- MINE

The `PasswordStore::setPassword` function is set to be an `external` function, however the purpose of the smart contract and function's natspec indicate that `This function allows only the owner to set a new password.`

```js
    /*
     * @notice This function allows only the owner to set a new password.
     * @param newPassword The new password to set.
     */
    // AUDIT access control not applying onlyOwner
    // Attack vector: missing access control
    function setPassword(string memory newPassword) external {
        s_password = newPassword;
        emit SetNetPassword();
    }
```

**Impact:** Anyone can set/change the password of the contract, severly breaking the contract intented functionality.

**Proof of Concept:** Add the following to the `PasswordStore.t.sol` test file

<details>
<summary>Code</summary>

```js
function test_anyone_can_set_password(address randomAddress) public {
    vm.assume(randomAddress != owner);
    vm.prank(randomAddress);
    string memory expectedPassword = "myNewPassword";
    passwordStore.setPassword(expectedPassword);

    vm.prank(owner);
    string memory actualPassword = passwordStore.getPassword();
    assertEq(actualPassword, expectedPassword);

}
```

</details>

**Recommended Mitigation:** Add an access control conditional to the `setPassword` function.

```js
if (msg.sender != s_owner) {
    revert PasswordStore__NotOwner();
}
```

# Informational
### [I-1] The `PasswordStore::getPassword` natspec indicates a parameter that doesn't exist, causing the natspec to be incorrect.

**Description:**

```js
/*
 * @notice This allows only the owner to retrieve the password.
@> * @param newPassword The new password to set.
 */
function getPassword() external view returns (string memory) {}
```

The `PasswordStore::getPassword` function signature is `getPassword()` while the natspec says it should be `getPassword(string)`.

**Impact:** Natspec is incorrect.

**Recommended Mitigation:** Remove the icorrect natspec line.

```diff
-     * @param newPassword The new password to set.
```
