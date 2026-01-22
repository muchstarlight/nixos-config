# NixOS Configuration

## Project Overview
This repository contains the NixOS configuration for the user `muchstarlight`, managed via **Nix Flakes**. It uses a modular structure to separate system-level configurations (`base`, `common`) from user-level configurations (managed via **Home Manager**).

**Primary Host:** `laptop` (x86_64-linux)

## Directory Structure

*   **`flake.nix`**: The entry point. Defines inputs (nixpkgs, home-manager) and the `nixosConfigurations` output.
*   **`hosts/`**: Contains host-specific configurations.
    *   `laptop/`: Configuration for the main laptop device.
        *   `configuration.nix`: Main system config, imports modules.
        *   `hardware-configuration.nix`: Hardware scan results.
*   **`modules/`**: Reusable Nix modules.
    *   `base/`: Core system settings (system defaults, users, security).
    *   `common/`: Feature-specific modules (NVIDIA, Audio, Bluetooth, Chinese software support, etc.).
    *   `home/`: Home Manager modules (shell setup, git, applications).
*   **`overlays/`**: Custom package overlays.

## Building and Running

To apply the configuration for the `laptop` host:

```bash
# Apply configuration
sudo nixos-rebuild switch --flake .#laptop

# Alternatively, if you are already on the 'laptop' hostname:
sudo nixos-rebuild switch --flake .
```

To update the flake inputs (e.g., update nixpkgs):

```bash
nix flake update
```

## Development Conventions

*   **Modularization:** Do not clutter `configuration.nix`. Create new modules in `modules/common` for distinct features and import them.
*   **Home Manager:** User-specific configuration (dotfiles, user packages) should go into `modules/home/`. This is integrated as a NixOS module in `flake.nix`.
*   **Language:** Documentation and comments may be in English or Chinese.
*   **Aliases:** defined in `modules/home/base.nix`:
    *   `nrebuild` -> `sudo nixos-rebuild switch`
    *   `fastfetch` -> `fastfetch -l arch`
