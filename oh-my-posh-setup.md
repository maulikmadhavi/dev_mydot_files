# Steps to Configure oh-my-posh on a New PC

This guide will walk you through the steps to configure `oh-my-posh` on a new Windows PC with PowerShell.

## Step 1: Install oh-my-posh

The easiest way to install `oh-my-posh` is by using `winget`. Open a new PowerShell window and run the following command:

```powershell
winget install JanDeDobbeleer.OhMyPosh -s winget
```

## Step 2: Install a Nerd Font

`oh-my-posh` uses special characters and symbols that are included in "Nerd Fonts". You need to install a Nerd Font and configure your terminal to use it.

1.  **Download a Nerd Font:** You can find a variety of Nerd Fonts on the official [Nerd Fonts website](https://www.nerdfonts.com/font-downloads). A popular choice is "FiraCode Nerd Font".
2.  **Install the font:** After downloading the font, right-click on the font file and select "Install".
3.  **Configure your terminal:** Open your terminal's settings and change the font to the Nerd Font you just installed.

## Step 3: Configure PowerShell Profile

Now, you need to configure your PowerShell profile to use `oh-my-posh`.

1.  **Open your PowerShell profile:** Open a new PowerShell window and run the following command to open your profile in Notepad:

    ```powershell
    if (-not (Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force }
    notepad $PROFILE
    ```

2.  **Add the `oh-my-posh` command:** Add the following line to your PowerShell profile and save the file:

    ```powershell
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/zash.omp.json" | Invoke-Expression
    ```

## Step 4: Create the Theme File

Finally, you need to create the `zash.omp.json` theme file.

1.  **Get the theme path:** Run the following command in your PowerShell window to get the path to your `oh-my-posh` themes folder:

    ```powershell
    $env:POSH_THEMES_PATH
    ```

2.  **Create the theme file:** Open the path you got from the previous command in File Explorer and create a new file named `zash.omp.json`.

3.  **Add the theme content:** Open the `zash.omp.json` file in a text editor and add the following content:

    ```json
    {
      "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
      "blocks": [
        {
          "type": "prompt",
          "alignment": "left",
          "segments": [
            {
              "type": "path",
              "style": "plain",
              "foreground": "#ffffff",
              "background": "#0077c2",
              "leading_diamond": "",
              "trailing_diamond": "",
              "properties": {
                "style": "full"
              }
            },
            {
              "type": "git",
              "style": "powerline",
              "powerline_symbol": "",
              "foreground": "#000000",
              "background": "#ffeb3b",
              "properties": {
                "branch_icon": "",
                "commit_icon": " ",
                "fetch_status": true,
                "fetch_upstream_icon": true
              }
            },
            {
              "type": "executiontime",
              "style": "powerline",
              "powerline_symbol": "",
              "foreground": "#ffffff",
              "background": "#2196f3",
              "properties": {
                "threshold": 500
              }
            }
          ]
        }
      ]
    }
    ```

4.  **Restart PowerShell:** Close and reopen your PowerShell window to see the new theme in action.
