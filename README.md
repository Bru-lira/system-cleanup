# 🧹 System Cleanup Tool

A Windows maintenance tool with a graphical interface, built with **PowerShell + WinForms**. It automates repetitive cleanup tasks — recycle bin, temporary files, and browser cache — without requiring technical knowledge from the end user.

🇧🇷 [Leia em Português](README.pt-BR.md)

![Status](https://img.shields.io/badge/status-approved%20in%20staging-brightgreen)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

## 📋 About

Keeping Windows clean usually means manually repeating the same actions: emptying the recycle bin, deleting temp files, clearing browser cache. This script brings those tasks together into a single panel, with visual feedback on what's happening and the result of each operation.

> **Note:** the script's UI and internal messages are in Portuguese (pt-BR), as it was originally built for Portuguese-speaking users. Code and comments are documented here in English for accessibility.

## ✨ Features

- **System cleanup**
  - Empty the Recycle Bin
  - Remove temporary files (`%TEMP%` and `C:\Windows\Temp`)
- **Browser cleanup (Chrome)**
  - Automatic detection of all installed profiles (including those linked to Google accounts)
  - Selective cache cleanup (Cache, Code Cache, GPUCache, Service Worker Cache, etc.)
  - **Browsing history and saved passwords are preserved** — only cache data is removed
- **Simple graphical interface** built with WinForms, no external dependencies
- Real-time status feedback for each operation
- Error handling isolated per task (a single failure doesn't stop the rest)

## 🖥️ Screenshots

| Main window | Task result |
|:---:|:---:|
| ![Main window](screenshots/screenshot-main.png) | ![Cleanup result](screenshots/screenshot-result.png) |

## ⚙️ Requirements

- Windows 10 or later
- PowerShell 5.1 or later (comes pre-installed on Windows)
- Google Chrome installed (only required for browser cache cleanup)

## 🚀 Usage

1. Download the `limpeza-sistema.ps1` file from this repository.
2. Right-click the file and select **"Run with PowerShell"**.
   - If script execution is blocked on your system, open PowerShell as administrator and run:
     ```powershell
     Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
     ```
     then run the script again.
3. In the window that opens:
   - Check the desired tasks in the **System** section and click **Executar Sistema** ("Run System").
   - Select the desired Chrome profile in the **Browser** section, check **Limpar cache do navegador** ("Clear browser cache"), and click **Executar Navegador** ("Run Browser").

## ⚠️ Important notes

- The script **automatically closes Chrome** before clearing the cache (required to release files in use). Save your work before running it.
- Cleaning temporary files and the recycle bin is **irreversible**. Use with caution.
- This project was developed and tested in a staging environment. Review the code before using it on production or critical machines.

## 🗂️ Project structure

```
├── system-cleanup.ps1     # Main script
├── system-cleanupBR.ps1   # Main script
├── LICENSE
├── .gitignore
├── README.md             # This file (English)
└── README.pt-BR.md       # Portuguese version
```

## 🛠️ Built with

- **PowerShell** — cleanup logic and file handling
- **Windows Forms (WinForms)** — graphical interface
- **JSON parsing** — reading Chrome's `Local State` file for profile detection

## 🤝 Contributing

Suggestions, fixes, and improvements are welcome! Feel free to open an issue or submit a pull request.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

Built by **Bruno Lira**.
# system-cleanup
