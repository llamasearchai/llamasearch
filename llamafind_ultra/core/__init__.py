"""
Core functionality for LlamaFind Ultra.

This module provides the foundational classes and functions used throughout
the LlamaFind Ultra system, including model wrappers, utility functions,
and base classes.
"""

from .model import (
    Model,
    ModelConfig,
    LocalModel,
    RemoteModel
)

from .config import (
    Config,
    load_config
)

__all__ = [
    "Model",
    "ModelConfig",
    "LocalModel",
    "RemoteModel",
    "Config",
    "load_config"
] 