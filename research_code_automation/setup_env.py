#!/usr/bin/env python3
"""
Environment setup script for Research Code Automation Tool.

This script helps set up a complete development environment including:
- Virtual environment creation
- Dependency installation
- Environment variables configuration
- Directory structure setup
- Basic checks for required system tools
"""

import os
import sys
import subprocess
import platform
import argparse
import shutil
import json
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()],
)
logger = logging.getLogger("setup_env")

# Constants
PROJECT_ROOT = Path(__file__).parent.parent.absolute()
PYTHON_MIN_VERSION = (3, 9)
VENV_DIR = PROJECT_ROOT / "venv"
DATA_DIR = PROJECT_ROOT / "data"
DOWNLOADS_DIR = PROJECT_ROOT / "downloads"
CACHE_DIR = PROJECT_ROOT / "cache"
ENV_FILE = PROJECT_ROOT / ".env"
ENV_EXAMPLE_FILE = PROJECT_ROOT / ".env.example"


def check_system_requirements():
    """Check that the system meets the requirements for the project."""
    logger.info("Checking system requirements...")
    
    # Check Python version
    python_version = sys.version_info
    if python_version < PYTHON_MIN_VERSION:
        logger.error(
            f"Python {PYTHON_MIN_VERSION[0]}.{PYTHON_MIN_VERSION[1]} or higher is required. "
            f"Found {python_version.major}.{python_version.minor}"
        )
        sys.exit(1)
    
    logger.info(f"Python version: {python_version.major}.{python_version.minor}.{python_version.micro}")
    
    # Check for pip
    try:
        subprocess.run([sys.executable, "-m", "pip", "--version"], check=True, capture_output=True)
    except subprocess.CalledProcessError:
        logger.error("pip is not installed or not working properly.")
        sys.exit(1)
    
    # Check for git
    try:
        subprocess.run(["git", "--version"], check=True, capture_output=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.warning("git is not installed or not in PATH. Some features may not work properly.")
    
    # Check for optional components based on OS
    system = platform.system().lower()
    
    if system == "linux":
        check_linux_dependencies()
    elif system == "darwin":
        check_macos_dependencies()
    elif system == "windows":
        check_windows_dependencies()
    
    logger.info("System requirements check completed.")


def check_linux_dependencies():
    """Check Linux-specific dependencies."""
    # Check for OCR dependencies
    try:
        subprocess.run(["tesseract", "--version"], check=True, capture_output=True)
        logger.info("Tesseract OCR is installed.")
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.warning("Tesseract OCR is not installed. OCR features will be limited.")
        logger.info("To install Tesseract: sudo apt-get install tesseract-ocr")
    
    try:
        subprocess.run(["ocrmypdf", "--version"], check=True, capture_output=True)
        logger.info("OCRmyPDF is installed.")
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.warning("OCRmyPDF is not installed. PDF OCR features will be limited.")
        logger.info("To install OCRmyPDF: sudo apt-get install ocrmypdf")
    
    # Check for FFmpeg (required for audio/video processing)
    try:
        subprocess.run(["ffmpeg", "-version"], check=True, capture_output=True)
        logger.info("FFmpeg is installed.")
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.warning("FFmpeg is not installed. Audio/video processing features will be limited.")
        logger.info("To install FFmpeg: sudo apt-get install ffmpeg")


def check_macos_dependencies():
    """Check macOS-specific dependencies."""
    # Check for Homebrew (recommended for installing dependencies)
    try:
        subprocess.run(["brew", "--version"], check=True, capture_output=True)
        logger.info("Homebrew is installed.")
        
        # Check for OCR dependencies with Homebrew
        try:
            subprocess.run(["tesseract", "--version"], check=True, capture_output=True)
            logger.info("Tesseract OCR is installed.")
        except (subprocess.CalledProcessError, FileNotFoundError):
            logger.warning("Tesseract OCR is not installed. OCR features will be limited.")
            logger.info("To install Tesseract: brew install tesseract")
        
        try:
            subprocess.run(["ocrmypdf", "--version"], check=True, capture_output=True)
            logger.info("OCRmyPDF is installed.")
        except (subprocess.CalledProcessError, FileNotFoundError):
            logger.warning("OCRmyPDF is not installed. PDF OCR features will be limited.")
            logger.info("To install OCRmyPDF: brew install ocrmypdf")
        
        # Check for FFmpeg
        try:
            subprocess.run(["ffmpeg", "-version"], check=True, capture_output=True)
            logger.info("FFmpeg is installed.")
        except (subprocess.CalledProcessError, FileNotFoundError):
            logger.warning("FFmpeg is not installed. Audio/video processing features will be limited.")
            logger.info("To install FFmpeg: brew install ffmpeg")
            
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.warning("Homebrew is not installed. It's recommended for installing dependencies on macOS.")
        logger.info("To install Homebrew: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")


def check_windows_dependencies():
    """Check Windows-specific dependencies."""
    # Check for chocolatey (recommended for installing dependencies on Windows)
    try:
        subprocess.run(["choco", "--version"], check=True, capture_output=True, shell=True)
        logger.info("Chocolatey is installed.")
        
        # Check for OCR dependencies
        try:
            # On Windows, tesseract might be in a different location
            tesseract_path = os.path.join(os.environ.get("ProgramFiles", "C:\\Program Files"), "Tesseract-OCR", "tesseract.exe")
            if os.path.exists(tesseract_path):
                logger.info("Tesseract OCR is installed.")
            else:
                logger.warning("Tesseract OCR is not installed. OCR features will be limited.")
                logger.info("To install Tesseract: choco install tesseract")
        except Exception:
            logger.warning("Tesseract OCR check failed. OCR features may be limited.")
        
        # Check for FFmpeg
        try:
            subprocess.run(["ffmpeg", "-version"], check=True, capture_output=True, shell=True)
            logger.info("FFmpeg is installed.")
        except (subprocess.CalledProcessError, FileNotFoundError):
            logger.warning("FFmpeg is not installed. Audio/video processing features will be limited.")
            logger.info("To install FFmpeg: choco install ffmpeg")
            
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.warning("Chocolatey is not installed. It's recommended for installing dependencies on Windows.")
        logger.info("To install Chocolatey, follow the instructions at: https://chocolatey.org/install")


def create_virtual_environment(force=False):
    """Create a virtual environment for the project."""
    logger.info("Setting up virtual environment...")
    
    if VENV_DIR.exists() and not force:
        logger.info(f"Virtual environment already exists at {VENV_DIR}. Use --force to recreate.")
        return
    
    if VENV_DIR.exists() and force:
        logger.info(f"Removing existing virtual environment at {VENV_DIR}...")
        shutil.rmtree(VENV_DIR)
    
    try:
        subprocess.run([sys.executable, "-m", "venv", str(VENV_DIR)], check=True)
        logger.info(f"Virtual environment created at {VENV_DIR}")
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to create virtual environment: {e}")
        sys.exit(1)


def get_pip_path():
    """Get the path to the pip executable in the virtual environment."""
    if platform.system().lower() == "windows":
        return VENV_DIR / "Scripts" / "pip.exe"
    else:
        return VENV_DIR / "bin" / "pip"


def get_python_path():
    """Get the path to the Python executable in the virtual environment."""
    if platform.system().lower() == "windows":
        return VENV_DIR / "Scripts" / "python.exe"
    else:
        return VENV_DIR / "bin" / "python"


def install_dependencies(dev=False, extras=None):
    """Install dependencies in the virtual environment."""
    logger.info("Installing dependencies...")
    
    pip_path = get_pip_path()
    
    # Upgrade pip and setuptools
    try:
        subprocess.run([str(pip_path), "install", "--upgrade", "pip", "setuptools", "wheel"], check=True)
        logger.info("Upgraded pip, setuptools, and wheel")
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to upgrade pip: {e}")
        sys.exit(1)
    
    # Install the package
    install_cmd = [str(pip_path), "install", "-e"]
    
    # Add extras if specified
    if extras:
        if isinstance(extras, str):
            extras = [extras]
        extras_str = ",".join(extras)
        install_cmd.append(f".[{extras_str}]")
    elif dev:
        install_cmd.append(".[dev,complete]")
    else:
        install_cmd.append(".")
    
    try:
        subprocess.run(install_cmd, check=True, cwd=PROJECT_ROOT)
        logger.info("Installed dependencies")
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to install dependencies: {e}")
        sys.exit(1)


def setup_environment_vars():
    """Set up environment variables for the project."""
    logger.info("Setting up environment variables...")
    
    if ENV_FILE.exists():
        logger.info(f"Environment file already exists at {ENV_FILE}")
        return
    
    if ENV_EXAMPLE_FILE.exists():
        logger.info(f"Creating environment file from example at {ENV_EXAMPLE_FILE}")
        shutil.copy(ENV_EXAMPLE_FILE, ENV_FILE)
    else:
        logger.info("Creating basic environment file")
        with open(ENV_FILE, "w") as f:
            f.write("# Research Code Automation Tool Environment Variables\n\n")
            f.write("# OpenAI API Key (required for AI text processing)\n")
            f.write("OPENAI_API_KEY=your_openai_api_key\n\n")
            f.write("# GitHub Token (optional, for higher GitHub API rate limits)\n")
            f.write("GITHUB_TOKEN=your_github_token\n\n")
            f.write("# LlamaSearch API URL\n")
            f.write("LLAMASEARCH_API_URL=http://localhost:8000/api\n\n")
            f.write("# Data directories\n")
            f.write(f"LLAMASEARCH_DATA_DIR={DATA_DIR}\n")
            f.write(f"LLAMASEARCH_CACHE_DIR={CACHE_DIR}\n")
            f.write(f"DOWNLOAD_DIR={DOWNLOADS_DIR}\n\n")
            f.write("# Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)\n")
            f.write("LOG_LEVEL=INFO\n\n")
            f.write("# Database URL (default: SQLite)\n")
            f.write("DATABASE_URL=sqlite:///./research_code_automation.db\n")
    
    logger.info(f"Environment file created at {ENV_FILE}")
    logger.info("Please edit the environment file to set your API keys and other configuration options.")


def setup_directory_structure():
    """Set up the directory structure for the project."""
    logger.info("Setting up directory structure...")
    
    # Create data directory
    DATA_DIR.mkdir(exist_ok=True)
    logger.info(f"Created data directory at {DATA_DIR}")
    
    # Create downloads directory
    DOWNLOADS_DIR.mkdir(exist_ok=True)
    logger.info(f"Created downloads directory at {DOWNLOADS_DIR}")
    
    # Create cache directory
    CACHE_DIR.mkdir(exist_ok=True)
    logger.info(f"Created cache directory at {CACHE_DIR}")


def run_tests():
    """Run the test suite to verify the installation."""
    logger.info("Running tests...")
    
    python_path = get_python_path()
    
    try:
        subprocess.run([str(python_path), "-m", "pytest", "-xvs"], check=True, cwd=PROJECT_ROOT)
        logger.info("All tests passed!")
    except subprocess.CalledProcessError as e:
        logger.error(f"Tests failed: {e}")
        logger.warning("Installation may not be complete or some dependencies may be missing.")
        return False
    
    return True


def check_tox():
    """Check if tox is installed and set up properly."""
    logger.info("Checking tox configuration...")
    
    pip_path = get_pip_path()
    
    # Install tox if not already installed
    try:
        subprocess.run([str(pip_path), "install", "tox"], check=True)
        logger.info("Tox is installed")
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to install tox: {e}")
        return False
    
    # Check tox.ini
    tox_ini = PROJECT_ROOT / "tox.ini"
    if not tox_ini.exists():
        logger.info("Creating basic tox.ini file")
        with open(tox_ini, "w") as f:
            f.write("[tox]\n")
            f.write("envlist = py39, py310, py311\n")
            f.write("isolated_build = True\n\n")
            f.write("[testenv]\n")
            f.write("deps =\n")
            f.write("    pytest>=7.4.0\n")
            f.write("    pytest-asyncio>=0.21.1\n")
            f.write("commands =\n")
            f.write("    pytest {posargs:tests}\n\n")
            f.write("[testenv:lint]\n")
            f.write("deps =\n")
            f.write("    black>=23.3.0\n")
            f.write("    isort>=5.12.0\n")
            f.write("    flake8>=6.0.0\n")
            f.write("    mypy>=1.3.0\n")
            f.write("commands =\n")
            f.write("    black --check research_code_automation tests\n")
            f.write("    isort --check-only research_code_automation tests\n")
            f.write("    flake8 research_code_automation tests\n")
            f.write("    mypy research_code_automation\n")
    
    return True


def install_pre_commit_hooks():
    """Install pre-commit hooks for development."""
    logger.info("Setting up pre-commit hooks...")
    
    pip_path = get_pip_path()
    
    # Install pre-commit
    try:
        subprocess.run([str(pip_path), "install", "pre-commit"], check=True)
        logger.info("pre-commit is installed")
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to install pre-commit: {e}")
        return False
    
    # Check for pre-commit config
    pre_commit_config = PROJECT_ROOT / ".pre-commit-config.yaml"
    if not pre_commit_config.exists():
        logger.info("Creating basic pre-commit config")
        with open(pre_commit_config, "w") as f:
            f.write("repos:\n")
            f.write("-   repo: https://github.com/pre-commit/pre-commit-hooks\n")
            f.write("    rev: v4.4.0\n")
            f.write("    hooks:\n")
            f.write("    -   id: trailing-whitespace\n")
            f.write("    -   id: end-of-file-fixer\n")
            f.write("    -   id: check-yaml\n")
            f.write("    -   id: check-added-large-files\n")
            f.write("-   repo: https://github.com/psf/black\n")
            f.write("    rev: 23.3.0\n")
            f.write("    hooks:\n")
            f.write("    -   id: black\n")
            f.write("-   repo: https://github.com/pycqa/isort\n")
            f.write("    rev: 5.12.0\n")
            f.write("    hooks:\n")
            f.write("    -   id: isort\n")
            f.write("-   repo: https://github.com/pycqa/flake8\n")
            f.write("    rev: 6.0.0\n")
            f.write("    hooks:\n")
            f.write("    -   id: flake8\n")
    
    # Install the hooks
    python_path = get_python_path()
    try:
        subprocess.run([str(python_path), "-m", "pre_commit", "install"], check=True, cwd=PROJECT_ROOT)
        logger.info("Pre-commit hooks installed")
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to install pre-commit hooks: {e}")
        return False
    
    return True


def setup_gpu_environment():
    """Set up GPU environment for machine learning tasks."""
    logger.info("Setting up GPU environment...")
    
    # Check for CUDA availability if using PyTorch
    python_path = get_python_path()
    
    try:
        result = subprocess.run(
            [str(python_path), "-c", "import torch; print(torch.cuda.is_available())"],
            check=True, capture_output=True, text=True
        )
        cuda_available = result.stdout.strip() == "True"
        
        if cuda_available:
            logger.info("CUDA is available for PyTorch!")
            
            # Get CUDA version
            result = subprocess.run(
                [str(python_path), "-c", "import torch; print(torch.version.cuda)"],
                check=True, capture_output=True, text=True
            )
            cuda_version = result.stdout.strip()
            logger.info(f"CUDA version: {cuda_version}")
            
            # Get GPU info
            result = subprocess.run(
                [str(python_path), "-c", "import torch; print(torch.cuda.get_device_name(0))"],
                check=True, capture_output=True, text=True
            )
            gpu_name = result.stdout.strip()
            logger.info(f"GPU: {gpu_name}")
        else:
            logger.warning("CUDA is not available for PyTorch. GPU acceleration will not be used.")
            
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.warning("Failed to check CUDA availability. PyTorch may not be installed correctly.")


def check_mlx_environment():
    """Check MLX environment for Apple Silicon."""
    logger.info("Checking MLX environment...")
    
    if platform.system().lower() != "darwin" or not platform.processor() == "arm":
        logger.info("MLX is only available on Apple Silicon Macs. Skipping MLX check.")
        return False
    
    python_path = get_python_path()
    
    try:
        result = subprocess.run(
            [str(python_path), "-c", "import mlx; print('MLX available')"],
            check=True, capture_output=True, text=True
        )
        if "MLX available" in result.stdout:
            logger.info("MLX is installed and available!")
            return True
        else:
            logger.warning("MLX may not be installed correctly.")
            return False
            
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.warning("MLX is not installed. Apple Silicon acceleration will not be used.")
        logger.info("To install MLX: pip install mlx")
        return False


def activate_environment_message():
    """Print message about activating the virtual environment."""
    if platform.system().lower() == "windows":
        activate_path = VENV_DIR / "Scripts" / "activate"
        activate_cmd = f"{activate_path}"
    else:
        activate_path = VENV_DIR / "bin" / "activate"
        activate_cmd = f"source {activate_path}"
    
    logger.info("\n" + "=" * 80)
    logger.info("Environment setup complete!")
    logger.info("=" * 80)
    logger.info(f"To activate the virtual environment, run:")
    logger.info(f"    {activate_cmd}")
    logger.info("=" * 80)


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Set up the development environment for Research Code Automation Tool.")
    parser.add_argument("--force", action="store_true", help="Force recreation of virtual environment if it already exists")
    parser.add_argument("--dev", action="store_true", help="Install development dependencies")
    parser.add_argument("--gpu", action="store_true", help="Set up GPU environment for machine learning tasks")
    parser.add_argument("--extras", nargs="+", help="Additional extras to install (e.g. ocr, scraping, academic)")
    parser.add_argument("--skip-tests", action="store_true", help="Skip running tests")
    parser.add_argument("--skip-hooks", action="store_true", help="Skip installing pre-commit hooks")
    
    return parser.parse_args()


def main():
    """Main entry point for the script."""
    args = parse_args()
    
    logger.info("Starting environment setup...")
    
    # Check system requirements
    check_system_requirements()
    
    # Set up directory structure
    setup_directory_structure()
    
    # Create virtual environment
    create_virtual_environment(args.force)
    
    # Install dependencies
    install_dependencies(dev=args.dev, extras=args.extras)
    
    # Set up environment variables
    setup_environment_vars()
    
    # Set up GPU environment if requested
    if args.gpu:
        setup_gpu_environment()
    
    # Check MLX environment on Apple Silicon
    if platform.system().lower() == "darwin" and platform.processor() == "arm":
        check_mlx_environment()
    
    # Check tox configuration
    check_tox()
    
    # Install pre-commit hooks if development mode is enabled and not skipped
    if args.dev and not args.skip_hooks:
        install_pre_commit_hooks()
    
    # Run tests if not skipped
    if not args.skip_tests:
        run_tests()
    
    # Print message about activating the virtual environment
    activate_environment_message()
    
    logger.info("Setup completed successfully!")


if __name__ == "__main__":
    main() 