#!/usr/bin/env python3
"""
Test file for MLX compatibility module

This file tests the MLX compatibility layer and demonstrates proper usage patterns.
"""

import os
import sys
import unittest
import numpy as np
from pathlib import Path

# Add the parent directory to the path so we can import the modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from llamafind_ultra.utils.mlx_compat import (
    MLX_AVAILABLE, 
    is_mlx_available, 
    get_mlx_version,
    mlx_textgen,
    mix_textgen,
    mIx_textgen,
    Im
)

class TestMLXCompat(unittest.TestCase):
    """Test the MLX compatibility layer"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_prompt = "This is a test prompt."
        self.test_model_path = "models/test_model.gguf"
        
        # Create a simple test image (3x3 RGB)
        self.test_image = np.zeros((3, 3, 3), dtype=np.uint8)
        self.test_image[0, 0] = [255, 0, 0]  # Red pixel at top-left
        self.test_image[1, 1] = [0, 255, 0]  # Green pixel at center
        self.test_image[2, 2] = [0, 0, 255]  # Blue pixel at bottom-right
    
    def test_mlx_availability(self):
        """Test the MLX availability check functions"""
        # Both functions should return the same value
        self.assertEqual(MLX_AVAILABLE, is_mlx_available())
        
        # Log the MLX version
        print(f"MLX available: {is_mlx_available()}, version: {get_mlx_version()}")
    
    def test_image_resize(self):
        """Test image resizing with MLX compatibility"""
        # Test resize to larger size
        resized = Im.resize(self.test_image, (5, 5))
        self.assertEqual(resized.shape, (5, 5, 3))
        
        # Test resize to smaller size
        resized = Im.resize(self.test_image, (2, 2))
        self.assertEqual(resized.shape, (2, 2, 3))
    
    def test_text_generation(self):
        """Test text generation with MLX compatibility"""
        # Test with default parameters
        result = mlx_textgen(self.test_prompt, self.test_model_path)
        self.assertIsInstance(result, str)
        self.assertGreater(len(result), 0)
        
        # Test with custom parameters
        result = mlx_textgen(
            self.test_prompt, 
            self.test_model_path,
            max_tokens=50,
            temperature=0.5,
            top_p=0.8
        )
        self.assertIsInstance(result, str)
        self.assertGreater(len(result), 0)
    
    def test_text_generation_alias(self):
        """Test text generation with the alias functions"""
        # Test mix_textgen (lowercase)
        result1 = mix_textgen(self.test_prompt, self.test_model_path)
        self.assertIsInstance(result1, str)
        self.assertGreater(len(result1), 0)
        
        # Test mIx_textgen (with capital I)
        result2 = mIx_textgen(self.test_prompt, self.test_model_path)
        self.assertIsInstance(result2, str)
        self.assertGreater(len(result2), 0)
        
        # Both should produce similar results
        self.assertEqual(result1, result2)

if __name__ == "__main__":
    unittest.main() 