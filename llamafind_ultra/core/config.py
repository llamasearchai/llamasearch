"""
Configuration handling for LlamaFind Ultra.

This module provides utilities for loading and managing application configuration.
"""

import os
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

import toml

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("llamafind.config")

@dataclass
class Config:
    """Application configuration.
    
    Attributes:
        app_name: Name of the application.
        version: Application version.
        debug: Whether to enable debug mode.
        server: Server configuration.
        models: Model configurations.
        search: Search configuration.
        api_keys: API keys for various services.
        features: Feature flags.
    """
    
    app_name: str = "LlamaFind Ultra"
    version: str = "1.0.0"
    debug: bool = False
    server: Dict[str, Any] = field(default_factory=lambda: {
        "host": "127.0.0.1",
        "port": 8000,
        "workers": 1,
        "timeout": 60
    })
    models: Dict[str, Any] = field(default_factory=dict)
    search: Dict[str, Any] = field(default_factory=dict)
    api_keys: Dict[str, str] = field(default_factory=dict)
    features: Dict[str, bool] = field(default_factory=lambda: {
        "mlx_enabled": False,
        "metrics_enabled": False,
        "search_enabled": True,
        "finance_enabled": True,
        "chat_enabled": True
    })
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert the configuration to a dictionary.
        
        Returns:
            Dictionary representation of the configuration.
        """
        result = {k: v for k, v in self.__dict__.items() if not k.startswith("_")}
        # Remove sensitive information like API keys
        if "api_keys" in result:
            masked_keys = {}
            for key_name, key_value in result["api_keys"].items():
                masked_keys[key_name] = "********" if key_value else None
            result["api_keys"] = masked_keys
        return result


def load_config(config_path: Optional[str] = None) -> Config:
    """Load configuration from a TOML file.
    
    Args:
        config_path: Path to the configuration file. If None, looks for the path
            in the LLAMASEARCH_CONFIG environment variable, or uses the default path.
            
    Returns:
        Loaded configuration.
        
    Raises:
        FileNotFoundError: If the configuration file is not found.
        ValueError: If the configuration file is invalid.
    """
    # Determine the configuration file path
    if config_path is None:
        config_path = os.environ.get("LLAMASEARCH_CONFIG", "config/llamafind.toml")
    
    config_file = Path(config_path)
    
    if not config_file.exists():
        logger.warning(f"Configuration file not found: {config_file}")
        logger.info("Using default configuration")
        return Config()
    
    try:
        logger.info(f"Loading configuration from {config_file}")
        config_data = toml.load(config_file)
        
        # Load API keys from environment variables
        api_keys = config_data.get("api_keys", {})
        for key_name, env_var in api_keys.items():
            if env_var.startswith("$"):
                env_name = env_var[1:]
                api_keys[key_name] = os.environ.get(env_name, "")
        
        # Create Config instance
        config = Config(
            app_name=config_data.get("app_name", "LlamaFind Ultra"),
            version=config_data.get("version", "1.0.0"),
            debug=config_data.get("debug", False),
            server=config_data.get("server", {}),
            models=config_data.get("models", {}),
            search=config_data.get("search", {}),
            api_keys=api_keys,
            features=config_data.get("features", {})
        )
        
        logger.info("Configuration loaded successfully")
        return config
        
    except Exception as e:
        logger.error(f"Error loading configuration: {e}")
        raise ValueError(f"Invalid configuration file: {e}")


def get_default_config_path() -> str:
    """Get the default configuration file path.
    
    Returns:
        Default configuration file path.
    """
    # Check environment variable first
    config_path = os.environ.get("LLAMASEARCH_CONFIG")
    if config_path:
        return config_path
    
    # Use default path relative to the current directory
    return "config/llamafind.toml" 