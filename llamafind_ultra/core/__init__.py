"""
Core functionality for LlamaFind Ultra.

This module provides the foundational classes and functions used throughout
the LlamaFind Ultra system, including model wrappers, utility functions,
and base classes.
"""

from .config import Config, load_config
from .model import LocalModel, Model, ModelConfig, RemoteModel

__all__ = ["Model", "ModelConfig", "LocalModel", "RemoteModel", "Config", "load_config"]
