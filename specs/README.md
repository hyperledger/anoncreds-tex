# Ursa Specification Papers

This folder is intended to be used for storing Latex files used for publishing
academic research about the cryptography used in Ursa.

The pattern for starting a new paper is to create a new folder and put 
the core latex file in there with the name *main.tex*. This allows the CI
pipeline to check for syntactic errors. Any other project related files should remain
in the project folder.

The paper should contain a section that indicates one of the following status':

- **In-Progress** indicates active changes are being made and new content is being added.
- **Proposed** means minimal changes are being made and discussions around including the cryptography in Ursa have started
- **Accepted** is used for papers that are completed and possibly published to conferences but no code has been implemented in Ursa 
- **Adopted** means Ursa code exists that implements the papers proposal. 
