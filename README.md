# FireSOC - Customized Atomic Red Team Tests

This repository contains a curated collection of Atomic Red Team tests, handpicked and customized to fit specific use cases. It includes some original tests, slight modifications to existing ones, and a few new additions.

## Features

- **Selected Atomic Red Team tests:** Carefully chosen for relevance and impact.
- **Modifications & enhancements:** Some tests are slightly altered to improve usability or fit particular scenarios.
- **New tests:** Additional tests created to complement the original collection.
- **PowerShell automation script:** Reads a list of tests from a file and executes them automatically.
- **Encrypted payloads:** All payloads are stored in password-protected ZIP archives for security and to avoid detection.

## Getting Started

1. Use the included prepare.ps1 PowerShell script to prepare the environment and download this repo.
2. The encrypted ZIP files require the password: `nevermind` (handled automatically by prepare.ps1)
3. Make sure to whitelist the necessary folders in your AV/EDR solutions to prevent blocking.

## Usage

- The main PowerShell script FireSOC.ps1 reads a list of tests from a specified file and runs them sequentially.
- Payload extraction is handled securely using the password-protected archives.
- Designed to be used in controlled SOC testing or red team engagements.

## Security Note

All modifications and additions are designed to improve test reliability while minimizing risk. The encrypted payloads protect against accidental execution and detection by endpoint protections.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

*Happy testing!*
