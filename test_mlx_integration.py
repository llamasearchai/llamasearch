#!/usr/bin/env python3
"""
MLX Integration Test Script for LlamaFind

This script tests the MLX integration in LlamaFind by initializing the MLX accelerator
and running various tests to verify that the functionality works correctly.
"""

import argparse
import json
import logging
import os
import sys
from typing import Any, Dict, List, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("mlx_test")

# Add the current directory to the path to ensure imports work correctly
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

# Import LlamaFind components
try:
    from llamafind.data_models import SearchResult
    from llamafind.mlx_compat import is_mlx_available, log_mlx_status, should_use_mlx

    HAS_LLAMAFIND = True
except ImportError as e:
    logger.error(f"LlamaFind package not found: {e}. Make sure it's installed.")
    HAS_LLAMAFIND = False
    sys.exit(1)

# Import MLX integration directly
if is_mlx_available():
    try:
        # Import directly from the module files
        from llamafind.mlx_embeddings import get_embedding_model
        from llamafind.mlx_generation import get_text_generator
        from llamafind.mlx_integration import MLXAccelerator, get_mlx_accelerator
        from llamafind.mlx_whisper import get_transcriber

        HAS_MLX_INTEGRATION = True
    except ImportError as e:
        logger.error(f"MLX integration module not found: {e}")
        HAS_MLX_INTEGRATION = False
else:
    logger.warning("MLX is not available on this system.")
    HAS_MLX_INTEGRATION = False


def test_mlx_status() -> Dict[str, Any]:
    """
    Test MLX status and availability.

    Returns:
        Dictionary with MLX status information
    """
    logger.info("Testing MLX status...")

    # Get MLX status
    status = log_mlx_status()

    # Print status information
    logger.info(f"MLX available: {status['mlx_available']}")
    if status["mlx_available"]:
        logger.info(f"MLX version: {status['mlx_version']}")

        # Log available packages
        packages = status["packages"]
        available_packages = [name for name, available in packages.items() if available]
        logger.info(f"Available MLX packages: {', '.join(available_packages)}")

        # Log compute units
        logger.info(
            f"MLX compute units: {status['config'].get('compute_units', 'unknown')}"
        )

    return status


def test_mlx_accelerator() -> Optional[Any]:
    """
    Test MLX accelerator initialization.

    Returns:
        MLX accelerator instance or None if initialization fails
    """
    if not HAS_MLX_INTEGRATION:
        logger.error("MLX integration not available, skipping accelerator test.")
        return None

    logger.info("Testing MLX accelerator initialization...")

    try:
        # Initialize MLX accelerator directly
        accelerator = MLXAccelerator()

        # Get status
        status = accelerator.get_status()

        # Log component status
        components = status.get("components", {})
        available_components = [
            name for name, available in components.items() if available
        ]
        logger.info(f"Available MLX components: {', '.join(available_components)}")

        return accelerator
    except Exception as e:
        logger.error(f"Failed to initialize MLX accelerator: {e}")
        return None


def test_embeddings(accelerator: Any) -> bool:
    """
    Test MLX embeddings functionality.

    Args:
        accelerator: MLX accelerator instance

    Returns:
        True if test passes, False otherwise
    """
    if not accelerator or not hasattr(accelerator, "embed_texts"):
        logger.error("MLX accelerator not available or doesn't support embeddings.")
        return False

    logger.info("Testing MLX embeddings...")

    try:
        # Test texts
        texts = [
            "This is a test sentence for embeddings.",
            "Another example to test vector representations.",
            "LlamaFind uses MLX for acceleration on Apple Silicon.",
        ]

        # Generate embeddings
        embeddings = accelerator.embed_texts(texts)

        if not embeddings or len(embeddings) != len(texts):
            logger.error(
                f"Embedding generation failed. Expected {len(texts)} embeddings, got {len(embeddings) if embeddings else 0}."
            )
            return False

        # Check embedding dimensions
        dimensions = len(embeddings[0])
        logger.info(f"Generated embeddings with dimension {dimensions}")

        # Check if embeddings are different (they should be for different texts)
        import numpy as np

        # Convert to numpy arrays for easier comparison
        embedding_arrays = [np.array(emb) for emb in embeddings]

        # Calculate cosine similarities
        similarities = []
        for i in range(len(embedding_arrays)):
            for j in range(i + 1, len(embedding_arrays)):
                # Normalize
                norm_i = np.linalg.norm(embedding_arrays[i])
                norm_j = np.linalg.norm(embedding_arrays[j])

                if norm_i > 0 and norm_j > 0:
                    # Calculate cosine similarity
                    similarity = np.dot(embedding_arrays[i], embedding_arrays[j]) / (
                        norm_i * norm_j
                    )
                    similarities.append(similarity)

        # Log similarities
        avg_similarity = sum(similarities) / len(similarities) if similarities else 0
        logger.info(f"Average similarity between embeddings: {avg_similarity:.4f}")

        return True
    except Exception as e:
        logger.error(f"Error testing embeddings: {e}")
        return False


def test_text_generation(accelerator: Any) -> bool:
    """
    Test MLX text generation functionality.

    Args:
        accelerator: MLX accelerator instance

    Returns:
        True if test passes, False otherwise
    """
    if not accelerator or not hasattr(accelerator, "generate_text"):
        logger.error(
            "MLX accelerator not available or doesn't support text generation."
        )
        return False

    logger.info("Testing MLX text generation...")

    try:
        # Test prompt
        prompt = "Explain the benefits of MLX for machine learning on Apple Silicon in one paragraph:"

        # Generate text
        generated_text = accelerator.generate_text(prompt, max_tokens=100)

        if not generated_text:
            logger.error("Text generation failed. No text was generated.")
            return False

        # Log generated text
        logger.info(
            f"Generated text ({len(generated_text)} chars): {generated_text[:100]}..."
        )

        # Test question answering
        question = "What are the main features of MLX?"
        answer = accelerator.answer_question(question)

        if not answer:
            logger.error("Question answering failed. No answer was generated.")
            return False

        # Log answer
        logger.info(f"Answer to question: {answer[:100]}...")

        # Test summarization
        text_to_summarize = """
        MLX is a machine learning framework designed specifically for Apple Silicon. 
        It provides high-performance implementations of common machine learning operations, 
        optimized for the unique architecture of Apple's M-series chips. MLX offers an array API 
        similar to NumPy, with automatic differentiation capabilities, and a neural network library 
        similar to PyTorch. The framework is designed to be efficient, flexible, and easy to use, 
        making it ideal for both research and production applications. MLX supports various hardware 
        backends, including the CPU, GPU, and Neural Engine on Apple Silicon devices, allowing developers 
        to take full advantage of the computational capabilities of these chips.
        """

        summary = accelerator.summarize(text_to_summarize)

        if not summary:
            logger.error("Summarization failed. No summary was generated.")
            return False

        # Log summary
        logger.info(f"Summary: {summary}")

        return True
    except Exception as e:
        logger.error(f"Error testing text generation: {e}")
        return False


def test_ranking(accelerator: Any) -> bool:
    """
    Test MLX ranking functionality.

    Args:
        accelerator: MLX accelerator instance

    Returns:
        True if test passes, False otherwise
    """
    if not accelerator or not hasattr(accelerator, "rank_results"):
        logger.error("MLX accelerator not available or doesn't support ranking.")
        return False

    logger.info("Testing MLX ranking...")

    try:
        # Create test search results
        results = [
            SearchResult(
                title="MLX: Efficient Machine Learning for Apple Silicon",
                url="https://example.com/mlx",
                text="MLX is an efficient machine learning framework designed specifically for Apple Silicon chips.",
                source="test",
                metadata={},
            ),
            SearchResult(
                title="PyTorch vs TensorFlow: A Comparison",
                url="https://example.com/pytorch-tensorflow",
                text="This article compares PyTorch and TensorFlow, two popular machine learning frameworks.",
                source="test",
                metadata={},
            ),
            SearchResult(
                title="Apple Silicon M2 Performance Benchmarks",
                url="https://example.com/m2-benchmarks",
                text="The Apple Silicon M2 chip shows impressive performance in machine learning workloads.",
                source="test",
                metadata={},
            ),
            SearchResult(
                title="Introduction to Neural Networks",
                url="https://example.com/neural-networks",
                text="Neural networks are a class of machine learning models inspired by the human brain.",
                source="test",
                metadata={},
            ),
            SearchResult(
                title="MLX vs PyTorch Performance on M1 Max",
                url="https://example.com/mlx-pytorch-m1",
                text="This benchmark compares MLX and PyTorch performance on the Apple M1 Max chip for various ML tasks.",
                source="test",
                metadata={},
            ),
        ]

        # Test query
        query = "MLX performance on Apple Silicon"

        # Rank results
        ranked_results = accelerator.rank_results(query, results)

        if not ranked_results or len(ranked_results) != len(results):
            logger.error(
                f"Ranking failed. Expected {len(results)} results, got {len(ranked_results) if ranked_results else 0}."
            )
            return False

        # Log ranking results
        logger.info("Ranking results:")
        for i, result in enumerate(ranked_results):
            similarity = result.metadata.get("similarity", "N/A")
            logger.info(f"{i+1}. {result.title} (similarity: {similarity})")

        # Test LLM reranking if available
        if hasattr(accelerator, "rerank_with_llm"):
            logger.info("Testing LLM reranking...")

            llm_ranked_results = accelerator.rerank_with_llm(query, results, top_k=3)

            if not llm_ranked_results:
                logger.warning("LLM reranking returned no results.")
            else:
                logger.info(
                    f"LLM reranking returned {len(llm_ranked_results)} results:"
                )
                for i, result in enumerate(llm_ranked_results):
                    logger.info(f"{i+1}. {result.title}")

        return True
    except Exception as e:
        logger.error(f"Error testing ranking: {e}")
        return False


def test_whisper(accelerator: Any, audio_file: Optional[str] = None) -> bool:
    """
    Test MLX Whisper functionality.

    Args:
        accelerator: MLX accelerator instance
        audio_file: Optional path to an audio file for testing

    Returns:
        True if test passes, False otherwise
    """
    if not accelerator or not hasattr(accelerator, "transcribe_audio"):
        logger.error("MLX accelerator not available or doesn't support Whisper.")
        return False

    if not audio_file:
        logger.warning("No audio file provided for Whisper test, skipping.")
        return False

    logger.info(f"Testing MLX Whisper with audio file: {audio_file}")

    try:
        # Check if file exists
        if not os.path.exists(audio_file):
            logger.error(f"Audio file not found: {audio_file}")
            return False

        # Transcribe audio
        result = accelerator.transcribe_audio(audio_file)

        if not result or "text" not in result:
            logger.error("Transcription failed. No text was generated.")
            return False

        # Log transcription
        transcription = result.get("text", "")
        logger.info(f"Transcription: {transcription}")

        return True
    except Exception as e:
        logger.error(f"Error testing Whisper: {e}")
        return False


def main():
    """Main entry point for the test script."""
    parser = argparse.ArgumentParser(description="LlamaFind MLX Integration Test")
    parser.add_argument(
        "--audio", "-a", type=str, help="Path to audio file for Whisper test"
    )
    parser.add_argument(
        "--output", "-o", type=str, help="Path to output JSON file for test results"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true", help="Enable verbose logging"
    )

    args = parser.parse_args()

    # Set logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Initialize test results
    test_results = {
        "mlx_available": is_mlx_available(),
        "mlx_integration_available": HAS_MLX_INTEGRATION,
        "tests": {},
    }

    # Test MLX status
    test_results["mlx_status"] = test_mlx_status()

    # Skip further tests if MLX is not available
    if not is_mlx_available() or not HAS_MLX_INTEGRATION:
        logger.error("MLX or MLX integration not available, skipping further tests.")

        # Save results if output file specified
        if args.output:
            with open(args.output, "w") as f:
                json.dump(test_results, f, indent=2)

        return 1

    # Test MLX accelerator
    accelerator = test_mlx_accelerator()
    test_results["accelerator_initialized"] = accelerator is not None

    if not accelerator:
        logger.error("MLX accelerator initialization failed, skipping further tests.")

        # Save results if output file specified
        if args.output:
            with open(args.output, "w") as f:
                json.dump(test_results, f, indent=2)

        return 1

    # Test embeddings
    test_results["tests"]["embeddings"] = test_embeddings(accelerator)

    # Test text generation
    test_results["tests"]["text_generation"] = test_text_generation(accelerator)

    # Test ranking
    test_results["tests"]["ranking"] = test_ranking(accelerator)

    # Test Whisper if audio file provided
    if args.audio:
        test_results["tests"]["whisper"] = test_whisper(accelerator, args.audio)

    # Calculate overall success
    test_results["success"] = all(test_results["tests"].values())

    # Log summary
    logger.info("\nTest Summary:")
    logger.info(f"MLX available: {test_results['mlx_available']}")
    logger.info(
        f"MLX integration available: {test_results['mlx_integration_available']}"
    )
    logger.info(f"Accelerator initialized: {test_results['accelerator_initialized']}")

    logger.info("\nTest Results:")
    for test_name, result in test_results["tests"].items():
        logger.info(f"{test_name}: {'PASS' if result else 'FAIL'}")

    logger.info(f"\nOverall: {'PASS' if test_results['success'] else 'FAIL'}")

    # Save results if output file specified
    if args.output:
        with open(args.output, "w") as f:
            json.dump(test_results, f, indent=2)
        logger.info(f"Test results saved to {args.output}")

    return 0 if test_results["success"] else 1


if __name__ == "__main__":
    sys.exit(main())
