# Modlist Automated Clicker (MAC)

<p align="center">
  <img src="img/mac-hq.png" alt="MAC mascot" width="220">
</p>

**Modlist Automated Clicker (MAC)** is a small Windows utility that automatically detects predefined PNG images inside a target application window and clicks them when they appear.

It is designed as a lightweight helper for repetitive UI interaction, with configurable image priority, variation tolerance, hotkey control, notifications, and built-in safety checks.

## Screenshot

![MAC main window](img/screenshot.png)

## Overview

MAC watches a selected application window by executable name and scans it for one or more PNG image references.  
When a match is found, it clicks the matching location, updates the click counter, and continues running until stopped.

The tool is distributed as a compiled `.exe`, so it can be launched directly on Windows without requiring the user to run the original AutoHotkey source script.

## Functionality

- Monitor a target application by executable name.
- Add one or multiple PNG files in a single action.
- Assign a variation value used during image matching.
- Reorder PNGs with **Up** and **Down** buttons to control search priority.
- Start and stop scanning from the GUI.
- Use a configurable toggle hotkey.
- Show current status, elapsed time, and total click count.
- Enable or disable popup notifications.
- Validate the selected target window before running.
- Validate PNG entries to detect missing or invalid files.
- Stop scanning if the target window is not active.

## How to use

1. Launch `Modlist Automated Clicker.exe`.
2. In **Target executable**, enter the executable name of the application you want MAC to monitor, for example:
   ```text
   Wabbajack.exe
   ```
3. Set or change the toggle hotkey if needed.
4. Set the image **Variation** value.
5. Click **Add PNG file(s)** and select one or more PNG references.
6. Arrange PNG priority with **Up** and **Down** if needed.
7. Optionally use **Test** and any validation features before starting.
8. Press **Start** to begin scanning.
9. Keep the target window active while MAC is running.

## Notes

- PNGs are checked in top-to-bottom order, so items higher in the list have higher priority.
- Variation controls how much visual difference is allowed when matching an image.
- For best results, use tightly cropped PNGs that contain only the clickable UI element.
- If the target window is not active, MAC can stop scanning and warn the user to prevent unintended clicks.
- Popup notifications can be disabled from the GUI.
- Because MAC is distributed as a compiled executable, no separate AutoHotkey installation is required for normal use.

## Requirements

- Windows
- The compiled `Modlist Automated Clicker.exe`

## Disclaimer

Use MAC only where UI automation is allowed.  
Some applications, launchers, or services may restrict or prohibit automated interaction.
