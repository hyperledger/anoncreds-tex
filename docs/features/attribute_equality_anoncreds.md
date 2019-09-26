# Zero-Knowledge Attribute equality in Anoncreds

## Overview
Anoncreds 1.0 and Anoncreds 2.0 papers describe how to prove equality of attributes across credentials without disclosing them. The idea is for the prover to use the same blinding factors for those attributes during commitment phase and the verifier to verify that indeed the same blinding factor was used. The Anoncreds code provides the API to allow prover to mark some attributes as common and hence use the same blinding factor for them across all credentials. But the verifier cannot mark attributes as common and hence check that same blinding factors were used. The doc describes the change made for the verifier. The [PR](https://github.com/hyperledger/ursa/pull/31) for the change. This document refers to the notation used in the [Anoncreds paper](https://github.com/hyperledger/ursa/blob/master/libursa/docs/AnonCred.pdf) in the Ursa repository.

## Detail

### Anoncreds 1.0
Prover uses the `ProofBuilder` object to create proofs. `ProofBuilder` object has a method called `add_common_attribute` that takes name of an attribute whose value has to be proved equal in all credentials. Link secret is one such attribute. The prover might use this method on additional attributes too depending on the proof request.

```rust
let mut proof_builder = Prover::new_proof_builder().unwrap();
// Prove link_secret is same in all credentials
proof_builder.add_common_attribute("master_secret").unwrap();
// Prove ssn is same in all credentials
proof_builder.add_common_attribute("ssn").unwrap();
```

Using `add_common_attribute` will make the `ProofBuilder` use the same blinding factor `m_tilde` (notation from paper) for all attributes with name `master_secret` (link secret but using the same name as code) in all credentials. Similarly for `ssn`, same `m_tilde` will be used in all credentials. Eg, `m_tilde`<sub>`0`</sub> will be used for `master_secret` and `m_tilde`<sub>`1`</sub> will be used for ssn. Now prover as part of the proof sends the opening for each common attribute `m_hat` (notation from paper).

```rust
// i corresponds to the attribute index
m_hat_i = m_tilde_i + challenge*m_i
```

The PR adds `add_common_attribute` method for verifier in ProofVerifier.

```rust
let mut proof_verifier = Verifier::new_proof_verifier().unwrap();
proof_verifier.add_common_attribute("master_secret").unwrap();
proof_verifier.add_common_attribute("ssn").unwrap();
```

**Note that the verifier should always call `add_common_attribute`("`master_secret`") unless he does not care about credentials having different link secrets.**
The verify method is changed to check that m_hat for all common attributes are equal. Hence the verifier will check that `m_hat` for `master_secret` in all sub proofs. Similarly verifier will check that `m_hat` for `ssn` is same in all sub-proofs.

The next step would be to support adding predicate in proof requests that lets a verifier specify which attributes are common in credentials.


### Anoncreds 2.0
For Anoncreds 2.0, we should take a different approach. The current model of Anoncreds 1.0 assumes that the common attributes are common for all credentials and hence verifier assumes all sub-proofs have that common attribute. But there will be cases where a proof is created from more than 2 credentials and some attribute has to be proven equal in only 2 credentials. Then the approach taken by Anoncreds 1.0 does not work. Next, the new approach is described. 
In Anoncreds 2.0, in the context of both `ProofBuilder` and `ProofVerifier`, each credential should be given a unique id. It can be counter, so first credential's id is 1, second credential id is 2, etc. Each attribute also has a unique id like \<credential id>.\<attribute name> so attribute name city of credential 3 has id "3.city". Both `ProofBuilder` and `ProofVerifier` support a new method called `add_equality_predicate` which takes a list of attribute ids which need to be proved equal.

```rust
fn add_equality_predicate(&mut self, attribute_ids: &HashSet[&str];
```

**Open question**: *Should attribute_ids be typed as BTreeSet since it will be used that way? The argument against that is it feels like exposing too much internals to the API consumer.*

The prover calling `proof_builder.add_equality_predicate(vec!["1.city", "3.city"].as_slice())` will create a proof proving city attribute of credential 1 and credential 3 are equal. Similarly the verifier calling `proof_verifier.add_equality_predicate(vec!["1.city", "3.city"].as_slice())` will check that the proof does prove that city attribute of credential 1 and credential 3 are equal. 

The `ProofBuilder` internally maintains a `HashMap` called `equalities` that maps set of attribute ids to the blinding factor, `HashMap<BTreeSet<String>, BigNumber>`. `BtreeSet` is chosen over `HashSet` since it has `Hash` trait implemented and it makes sense to have an ordered collection as Hashable. Thus the result of calling `add_equality_predicate` is that it 

- checks if any of the passed attribute ids is part of the equalities hashmap by trying to find a non-empty intersection (after set conversion) of attribute_ids with keys of the equalities hashmap, if successful, updates the corresponding key of the hashmap by doing a union and returns, else move to next step 
- creates a set with passed attribute ids, creates a blinding factor `m_tilde` as the value and inserts the key value in the hashmap.

When proof is being created, the equalities hashmap is first checked and if any attribute is present in any key, then the corresponding blinding factor is used. Otherwise a new blinding factor is created.

The `ProofVerifier` internally maintains a hashmap called `equalities` that maps set of attribute ids to the blinding factor, `HashMap<BTreeSet<String>, Option<BigNumber>>`. The value is of type `Option` since it will not have any value until `verify` is called but `add_equality_predicate` will be called before that. The result of calling `add_equality_predicate` is that it

- checks if any of the passed attribute ids is part of the `equalities` hashmap by trying to find a non-empty intersection (after set conversion) of attribute_ids with keys of the `equalities` hashmap, if successful, updates the corresponding key of the hashmap by doing a union and returns, else move to next step.
- creates a set with passed attribute ids, sets the value as None and inserts the key value in the hashmap.

When proof is being verified, each attribute is checked for presence in the `equalities` hashmap.
If the attribute id is present in any key

- Check if the value is None.
- If None then set the value as the attribute's `m_hat`
- If not None, then compare the value with attribute's `m_hat`. 
  - If they are unequal, then verification has failed and abort. 
  - Else continue
 
Since the way the keys of `equalities` `HashMap` is updated is similar for both `ProofBuilder` and `ProofVerifier`, a generic function typed for the value called `update_equalities_key` that takes the attribute ids as argument can be created that is used by both `ProofBuilder` and `ProofVerifier`.

```rust
fn update_equalities_key<T>(map: &mut HashMap<BTreeSet<String>, T>;
```

The existing `add_common_attribute` of both `ProofBuilder` and `ProofVerifier` can be seen as a special case of `add_equality_predicate` and thus calling `add_common_attribute` also update the `equalities` HashMap. eg. In a 3 credential example, calling

```rust
add_common_attribute("link_secret")
```

is equivalent to calling

```rust
add_equality_predicate(vec!["1.link_secret", "2.link_secret", 3.link_secret"].as_slice())
```