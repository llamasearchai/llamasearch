"""
Model classes for LlamaFind Ultra.

This module provides base classes and implementations for different types of models
that can be used by the platform, including local models and remote API-based models.
"""

import logging
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Union

# Setup logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)


@dataclass
class ModelConfig:
    """Configuration for a model.

    Attributes:
        name: Name of the model.
        description: Description of the model.
        model_type: Type of model (e.g., "local", "remote").
        framework: Framework used for the model (e.g., "pytorch", "openai", "anthropic").
        model_id: ID or name of the model (e.g., "gpt-4", "claude-3-opus").
        model_path: Path to the model files (for local models).
        api_base: Base URL for API (for remote models).
        api_key: API key for authentication (for remote models).
        requires_gpu: Whether the model requires a GPU.
        max_input_length: Maximum input length in tokens.
        max_output_length: Maximum output length in tokens.
        params: Additional parameters for the model.
    """

    name: str
    description: str = "Model configuration"
    model_type: str = "remote"
    framework: str = "openai"
    model_id: Optional[str] = None
    model_path: Optional[str] = None
    api_base: Optional[str] = None
    api_key: Optional[str] = None
    requires_gpu: bool = False
    max_input_length: int = 4096
    max_output_length: int = 1024
    params: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert the configuration to a dictionary.

        Returns:
            Dictionary representation of the configuration.
        """
        result = {k: v for k, v in self.__dict__.items() if not k.startswith("_")}
        # Remove sensitive information like API keys
        if "api_key" in result:
            result["api_key"] = "********" if result["api_key"] else None
        return result


class Model(ABC):
    """Base class for all models in LlamaFind Ultra.

    This is an abstract base class that defines the interface for all models
    that can be used in the platform. Concrete implementations should inherit
    from this class and implement its abstract methods.
    """

    def __init__(self, config: Union[Dict[str, Any], ModelConfig]):
        """Initialize the model.

        Args:
            config: Model configuration, either as a dictionary or a ModelConfig instance.
        """
        if isinstance(config, dict):
            self.config = ModelConfig(**config)
        else:
            self.config = config

        self.name = self.config.name
        self.model_type = self.config.model_type
        self.framework = self.config.framework
        self.is_loaded = False
        self._model = None
        self.logger = logging.getLogger(f"llamafind.model.{self.name}")

    @abstractmethod
    def load(self) -> None:
        """Load the model into memory or initialize the API client."""
        pass

    @abstractmethod
    def unload(self) -> None:
        """Unload the model from memory or clean up resources."""
        pass

    @abstractmethod
    def predict(self, inputs: Any, **kwargs) -> Any:
        """Run prediction with the model.

        Args:
            inputs: Input data for the model.
            **kwargs: Additional parameters for prediction.

        Returns:
            Prediction results.
        """
        pass

    def __enter__(self):
        """Context manager entry.

        Returns:
            The model instance.
        """
        self.load()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.unload()


class LocalModel(Model):
    """Model that runs locally, loaded into memory.

    This class represents a model that is loaded into local memory for inference.
    It can be used with various frameworks such as PyTorch, TensorFlow, or ONNX.
    """

    def load(self) -> None:
        """Load the model into memory.

        Raises:
            FileNotFoundError: If the model file is not found.
            RuntimeError: If there's an error loading the model.
        """
        if self.is_loaded:
            return

        self.logger.info(f"Loading model {self.name} from {self.config.model_path}")

        try:
            # Handle different framework types
            if self.framework == "pytorch":
                self._load_pytorch_model()
            elif self.framework == "mlx":
                self._load_mlx_model()
            else:
                raise ValueError(f"Unsupported framework: {self.framework}")

            self.is_loaded = True
            self.logger.info(f"Model {self.name} loaded successfully")

        except FileNotFoundError as e:
            self.logger.error(f"Model file not found: {e}")
            raise

        except Exception as e:
            self.logger.error(f"Error loading model: {e}")
            raise RuntimeError(f"Failed to load model: {e}")

    def unload(self) -> None:
        """Unload the model from memory."""
        if not self.is_loaded:
            return

        self.logger.info(f"Unloading model {self.name}")

        # Clean up resources
        self._model = None
        self.is_loaded = False

        self.logger.info(f"Model {self.name} unloaded successfully")

    def predict(self, inputs: Union[str, List[str]], **kwargs) -> Any:
        """Run prediction with the model.

        Args:
            inputs: Input text or list of texts.
            **kwargs: Additional parameters for prediction.

        Returns:
            Prediction results.

        Raises:
            RuntimeError: If the model is not loaded or there's an error during prediction.
        """
        if not self.is_loaded:
            self.logger.warning("Model not loaded, loading now")
            self.load()

        try:
            # Record start time for latency measurement
            start_time = time.time()

            # Handle batch or single input
            if isinstance(inputs, list):
                results = [
                    self._model_predict(input_text, **kwargs) for input_text in inputs
                ]
            else:
                results = self._model_predict(inputs, **kwargs)

            # Record end time for latency measurement
            end_time = time.time()
            latency = end_time - start_time

            # Add metadata to results if it's a dictionary
            if isinstance(results, dict):
                results["metadata"] = {"latency_seconds": latency}

            return results

        except Exception as e:
            self.logger.error(f"Error during prediction: {e}")
            raise RuntimeError(f"Prediction failed: {e}")

    def _model_predict(self, input_text: str, **kwargs) -> Any:
        """Internal method for model prediction."""
        # This should be implemented by subclasses
        raise NotImplementedError("Subclasses must implement _model_predict")

    def _load_pytorch_model(self) -> None:
        """Load a PyTorch model."""
        try:
            import torch

            self.logger.info("Using PyTorch framework")

            # This is a placeholder - would be implemented with specific model loading
            self._model = "pytorch_model_placeholder"

        except ImportError:
            self.logger.error("PyTorch not installed")
            raise RuntimeError("PyTorch is required but not installed")

    def _load_mlx_model(self) -> None:
        """Load an MLX model."""
        try:
            import mlx

            self.logger.info("Using MLX framework")

            # This is a placeholder - would be implemented with specific model loading
            self._model = "mlx_model_placeholder"

        except ImportError:
            self.logger.error("MLX not installed")
            raise RuntimeError("MLX is required but not installed")


class RemoteModel(Model):
    """Model that runs on a remote server, accessed via API.

    This class represents a model that is hosted remotely and accessed via an API.
    It can be used with various LLM services such as OpenAI, Anthropic, Cohere, etc.
    """

    def load(self) -> None:
        """Initialize the API client.

        Raises:
            ValueError: If API configuration is missing.
            RuntimeError: If there's an error initializing the API client.
        """
        if self.is_loaded:
            return

        if not self.config.api_key:
            self.logger.error("API key is required for remote models")
            raise ValueError("API key is required for remote models")

        api_base = self.config.api_base
        if not api_base and self.framework == "openai":
            api_base = "https://api.openai.com/v1"
        elif not api_base and self.framework == "anthropic":
            api_base = "https://api.anthropic.com/v1"

        self.logger.info(f"Initializing API client for {self.name} at {api_base}")

        try:
            # Initialize the appropriate API client
            if self.framework == "openai":
                self._init_openai_client()
            elif self.framework == "anthropic":
                self._init_anthropic_client()
            else:
                # Generic API client
                self._model = {
                    "client_type": "generic",
                    "api_base": api_base,
                    "model_id": self.config.model_id,
                }

            self.is_loaded = True
            self.logger.info(f"API client for {self.name} initialized successfully")

        except Exception as e:
            self.logger.error(f"Error initializing API client: {e}")
            raise RuntimeError(f"Failed to initialize API client: {e}")

    def unload(self) -> None:
        """Clean up API client resources."""
        if not self.is_loaded:
            return

        self.logger.info(f"Cleaning up API client resources for {self.name}")

        # Clean up resources
        self._model = None
        self.is_loaded = False

        self.logger.info(f"API client for {self.name} cleaned up successfully")

    def predict(self, inputs: Union[str, List[str]], **kwargs) -> Any:
        """Run prediction with the remote model API.

        Args:
            inputs: Input text or list of texts.
            **kwargs: Additional parameters for the API call.

        Returns:
            API response.

        Raises:
            RuntimeError: If the client is not initialized or there's an error during the API call.
        """
        if not self.is_loaded:
            self.logger.warning("API client not initialized, initializing now")
            self.load()

        try:
            # Record start time for latency measurement
            start_time = time.time()

            # Handle batch or single input
            if isinstance(inputs, list):
                results = [
                    self._api_call(input_text, **kwargs) for input_text in inputs
                ]
            else:
                results = self._api_call(inputs, **kwargs)

            # Record end time for latency measurement
            end_time = time.time()
            latency = end_time - start_time

            # Add metadata to results if it's a dictionary
            if isinstance(results, dict):
                results["metadata"] = {"latency_seconds": latency}

            return results

        except Exception as e:
            self.logger.error(f"Error during API call: {e}")
            raise RuntimeError(f"API call failed: {e}")

    def _api_call(self, input_text: str, **kwargs) -> Any:
        """Internal method for API call.

        Args:
            input_text: Input text.
            **kwargs: Additional parameters.

        Returns:
            API response.
        """
        # This should be overridden by subclasses to make actual API calls
        raise NotImplementedError("Subclasses must implement _api_call")

    def _init_openai_client(self) -> None:
        """Initialize OpenAI API client."""
        try:
            import openai

            self.logger.info("Using OpenAI API")

            client = openai.Client(api_key=self.config.api_key)

            self._model = {
                "client_type": "openai",
                "client": client,
                "model_id": self.config.model_id or "gpt-3.5-turbo",
            }

        except ImportError:
            self.logger.error("OpenAI package not installed")
            raise RuntimeError("OpenAI package is required but not installed")

    def _init_anthropic_client(self) -> None:
        """Initialize Anthropic API client."""
        try:
            import anthropic

            self.logger.info("Using Anthropic API")

            client = anthropic.Anthropic(api_key=self.config.api_key)

            self._model = {
                "client_type": "anthropic",
                "client": client,
                "model_id": self.config.model_id or "claude-3-opus-20240229",
            }

        except ImportError:
            self.logger.error("Anthropic package not installed")
            raise RuntimeError("Anthropic package is required but not installed")
