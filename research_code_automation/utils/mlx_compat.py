"""MLX compatibility module for Apple Silicon machines."""

import os
import sys
import platform
import logging
from typing import Optional, Dict, Any, Union, List, Tuple

import numpy as np

from research_code_automation.config import settings

logger = logging.getLogger(__name__)

# Detect platform
IS_APPLE_SILICON = platform.system() == "Darwin" and platform.processor() == "arm"

# Only import mlx on Apple Silicon if USE_MLX is True
if IS_APPLE_SILICON and settings.use_mlx:
    try:
        mlx_available = False
        # Try to import MLX
        try:
            import mlx.core
            mlx_available = True
        except ImportError:
            logger.warning("MLX not found. MLX acceleration will not be available.")
    except Exception as e:
        logger.warning(f"Error importing MLX: {e}")
        mlx_available = False
else:
    mlx_available = False


def is_mlx_available() -> bool:
    """
    Check if MLX is available on this system.
    
    Returns:
        True if MLX is available, False otherwise
    """
    return mlx_available


def to_mlx(tensor: Union[np.ndarray, List, Tuple]) -> Any:
    """
    Convert a NumPy array or Python list/tuple to MLX tensor.
    
    Args:
        tensor: NumPy array or Python list/tuple
        
    Returns:
        MLX tensor or original input if MLX is not available
    """
    if not mlx_available:
        return tensor
    
    import mlx.core
    
    if isinstance(tensor, np.ndarray):
        return mlx.core.array(tensor)
    elif isinstance(tensor, (list, tuple)):
        return mlx.core.array(np.array(tensor))
    else:
        return tensor


def to_numpy(tensor: Any) -> np.ndarray:
    """
    Convert an MLX tensor to NumPy array.
    
    Args:
        tensor: MLX tensor or other object
        
    Returns:
        NumPy array
    """
    if not mlx_available:
        if isinstance(tensor, np.ndarray):
            return tensor
        elif isinstance(tensor, (list, tuple)):
            return np.array(tensor)
        else:
            return np.array(tensor)
    
    import mlx.core
    
    if isinstance(tensor, mlx.core.array):
        return tensor.tolist()
    elif isinstance(tensor, np.ndarray):
        return tensor
    elif isinstance(tensor, (list, tuple)):
        return np.array(tensor)
    else:
        return np.array(tensor)


def get_device_info() -> Dict[str, Any]:
    """
    Get information about the compute device.
    
    Returns:
        Dictionary with device information
    """
    device_info = {
        "platform": platform.system(),
        "processor": platform.processor(),
        "is_apple_silicon": IS_APPLE_SILICON,
        "mlx_available": mlx_available,
    }
    
    if mlx_available:
        import mlx.core
        
        # Add MLX-specific information
        device_info["mlx_version"] = mlx.__version__
        
        # Create a small tensor to check if MLX is working
        try:
            x = mlx.core.ones((2, 2))
            y = mlx.core.ones((2, 2))
            z = x + y
            device_info["mlx_working"] = True
        except Exception as e:
            device_info["mlx_working"] = False
            device_info["mlx_error"] = str(e)
    
    return device_info 