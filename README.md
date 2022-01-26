#What is this?

When you have a fresh Windows 10/11 environment it can be annoying to install every SINGLE piece of software you need. 

This powershell script will download the `install` and `uninstall` text files in this repo and run `winget` on each line of the install file and attempt to uninstall any Windows Store apps listed in the uninstall file.

Note: You need to have run a `winget` command to accept the agreement otherwise this script will fail.

Elevated permissions are required to perform the uninstall.

You are free to fork this repo and modify the in/uninstall files to your hearts content.

## The command
The `-url` argument is the base path for your install and uninstall files.

You can provide one or both of `-install` and `-uninstall`. If you just provide `-install`, the uninstall section won't run.

Run this from a powershell window
```bh
iex "& { $(irm https://raw.githubusercontent.com/Eonasdan/desktop-automation/main/automate.ps1) } -url https://raw.githubusercontent.com/Eonasdan/desktop-automation/main -install -uninstall"
```



Adapted and improved from https://chrislayers.com/2021/08/01/scripting-winget/