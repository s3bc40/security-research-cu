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

## Timeboxing:
> I think we should just double check our findings, see if there are any errors in our report writing. Checking specificaly our findings will allow to assess our work without getting caught in the 'doubt cycle'. We'll just have to submit and see the result afterward, rather than not subimiting something or messing up our research review.

