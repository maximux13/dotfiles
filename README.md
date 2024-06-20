# Dotfiles Configuration

This repository contains my personal dotfiles for various tools and applications like tmux, Alacritty, and Zsh. It uses GNU Stow to manage and link these configuration files easily across different systems.

## Getting Started

### Prerequisites

Before you clone this repository and start using the dotfiles, ensure you have GNU Stow installed on your system. You can install Stow using the following command on most Unix-like operating systems:

```bash
sudo apt-get install stow # Debian/Ubuntu
brew install stow # macOS
```

### Installation

To clone the repository and set up the dotfiles, follow these steps:

1. Clone the repository:

```bash
git clone https://github.com/maximux13/dotfiles.git
cd dotfiles
```

2. Deploy the dotfiles using Stow. For example, to set up the tmux configuration:

```bash
stow tmux
```

Repeat the above step for each configuration set you want to apply, like `alacritty`, `zsh`, etc.

### Homebrew Installation (macOS)

If you are using macOS, you can use the provided `install.sh` script to install all the necessary dependencies via Homebrew. To do so, run the following commands:

```bash
cd path/to/dotfiles/homebrew
chmod +x install.sh
./install.sh
```

## Customization

Feel free to fork this repository and customize the dotfiles to suit your needs. You can modify the existing files or add new configurations and use Stow to manage them as demonstrated above.

## Contributing

Contributions to improve these dotfiles or add new configurations are always welcome. Please feel free to submit a pull request or open an issue if you have suggestions or improvements.

## License

This project is open-source and available under the [MIT License](LICENSE).
