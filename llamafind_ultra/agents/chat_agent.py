"""
Chat agent for LlamaFind Ultra.

This module provides the ChatAgent class, which handles conversational
interactions using LLMs.
"""

import logging
import time
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional, Union

from .base import Agent, AgentConfig, AgentMessage, AgentResponse
from ..core.model import Model, RemoteModel, ModelConfig

logger = logging.getLogger("llamafind.agents.chat")

class ChatAgent(Agent):
    """Agent for conversational interactions.
    
    This agent can handle chat-based interactions and provide responses
    using underlying language models.
    """
    
    def __init__(self, config: Union[Dict[str, Any], AgentConfig], model: Optional[Model] = None):
        """Initialize the chat agent.
        
        Args:
            config: Agent configuration.
            model: Model to use for chat responses. If None, a model will be
                loaded based on the configuration if needed.
        """
        # Set default agent type if not provided
        if isinstance(config, dict) and "agent_type" not in config:
            config["agent_type"] = "chat"
        elif isinstance(config, AgentConfig) and config.agent_type == "base":
            config.agent_type = "chat"
        
        super().__init__(config, model)
        
        # Initialize the model if not provided
        if self.model is None and self.config.model_name:
            self._initialize_model()
        
        # Add default capabilities if not provided
        if not self.config.capabilities:
            self.config.capabilities = ["chat", "get_current_time", "get_weather"]
        
        # Initialize tasks storage
        self.tasks = {}
        
        # Define system prompt
        self.system_prompt = self.config.params.get("system_prompt", 
            "You are a helpful assistant. Provide concise and accurate information. " +
            "If you don't know the answer, say so instead of making it up."
        )
    
    def process_message(self, message: Union[str, AgentMessage]) -> AgentResponse:
        """Process a message and generate a chat response.
        
        Args:
            message: Message to process.
            
        Returns:
            Agent response.
        """
        # Create message object if needed
        message_obj = self._create_message(message)
        self._add_to_history(message_obj)
        
        logger.info(f"Processing chat message: {message_obj.content}")
        
        try:
            # Check for special commands or capabilities
            query = message_obj.content.strip().lower()
            
            if "time" in query and "what" in query:
                response_content = self._get_current_time()
            elif "weather" in query and any(word in query for word in ["what", "how"]):
                response_content = self._get_weather_placeholder()
            else:
                # Use the model for general chat responses if available
                if self.model:
                    response_content = self._generate_model_response(message_obj)
                else:
                    response_content = "I'm a chat agent, but I don't have a language model configured yet. I can tell you the current time if you ask."
            
            # Create and return response
            response = self._create_response(response_content, message_obj)
            self._add_to_history(response)
            
            return response
            
        except Exception as e:
            logger.error(f"Error processing chat message: {e}")
            error_response = self._create_response(
                f"Sorry, I encountered an error while processing your message: {str(e)}",
                message_obj
            )
            self._add_to_history(error_response)
            return error_response
    
    def create_task(self, description: str) -> str:
        """Create a chat task.
        
        Args:
            description: Description of the chat task.
            
        Returns:
            Task ID.
        """
        logger.info(f"Creating chat task: {description}")
        
        # Create a task ID
        task_id = f"chat_task_{int(time.time())}_{len(self.tasks)}"
        
        # Store the task
        self.tasks[task_id] = {
            "id": task_id,
            "description": description,
            "status": "created",
            "created_at": time.time(),
            "updated_at": time.time(),
            "result": None,
            "error": None
        }
        
        logger.info(f"Created task {task_id}")
        return task_id
    
    def run_task(self, task_id: str) -> Dict[str, Any]:
        """Run a chat task.
        
        Args:
            task_id: ID of the task to run.
            
        Returns:
            Task result.
            
        Raises:
            ValueError: If the task is not found.
        """
        logger.info(f"Running chat task: {task_id}")
        
        # Check if task exists
        if task_id not in self.tasks:
            raise ValueError(f"Task not found: {task_id}")
        
        # Get the task
        task = self.tasks[task_id]
        
        # Update task status
        task["status"] = "running"
        task["updated_at"] = time.time()
        
        try:
            # Process the task description as a message
            description = task["description"]
            message = AgentMessage(content=description)
            
            # Generate a response
            response = self.process_message(message)
            
            # Update task with results
            task["result"] = {
                "content": response.content,
                "timestamp": time.time(),
                "response_id": response.response_id
            }
            task["status"] = "completed"
            
        except Exception as e:
            logger.error(f"Error running chat task {task_id}: {e}")
            task["status"] = "failed"
            task["error"] = str(e)
        
        # Update task timestamp
        task["updated_at"] = time.time()
        
        return task
    
    def _initialize_model(self) -> None:
        """Initialize the language model based on configuration."""
        try:
            logger.info(f"Initializing model: {self.config.model_name}")
            
            # Create a simple model config
            model_config = ModelConfig(
                name=self.config.model_name,
                model_type="remote",
                framework="openai",  # Default framework
                model_id=self.config.model_name,
            )
            
            # Override settings from config params if available
            model_params = self.config.params.get("model", {})
            if "framework" in model_params:
                model_config.framework = model_params["framework"]
            
            if "api_key" in model_params:
                model_config.api_key = model_params["api_key"]
                
            # Create the model instance
            self.model = RemoteModel(model_config)
            logger.info(f"Model initialized: {self.config.model_name}")
            
        except Exception as e:
            logger.error(f"Error initializing model: {e}")
            self.model = None
    
    def _generate_model_response(self, message: AgentMessage) -> str:
        """Generate a response using the language model.
        
        Args:
            message: User message.
            
        Returns:
            Model-generated response.
        """
        try:
            # Format conversation history for the model
            messages = [
                {"role": "system", "content": self.system_prompt}
            ]
            
            # Add conversation history (limited to last 10 messages)
            history = self.conversation_history[-10:]
            for item in history:
                if isinstance(item, AgentMessage) and item.message_type == "user":
                    messages.append({"role": "user", "content": item.content})
                elif isinstance(item, AgentResponse):
                    messages.append({"role": "assistant", "content": item.content})
            
            # Ensure the last message is the current one
            if messages[-1]["role"] != "user" or messages[-1]["content"] != message.content:
                messages.append({"role": "user", "content": message.content})
            
            # Call the model
            response = self.model.predict(messages)
            
            # Extract the response content based on the model framework
            if self.model.framework == "openai":
                return response.get("choices", [{}])[0].get("message", {}).get("content", "")
            elif self.model.framework == "anthropic":
                return response.get("content", [{}])[0].get("text", "")
            else:
                # Generic extraction, may need to be adapted for other models
                if isinstance(response, dict):
                    return str(response.get("content", ""))
                else:
                    return str(response)
                
        except Exception as e:
            logger.error(f"Error generating model response: {e}")
            return "I'm having trouble accessing my language model right now. Please try again later."
    
    def _get_current_time(self) -> str:
        """Get the current time.
        
        Returns:
            Current time as a string.
        """
        now = datetime.now()
        return f"The current time is {now.strftime('%H:%M:%S')} on {now.strftime('%A, %B %d, %Y')}."
    
    def _get_weather_placeholder(self) -> str:
        """Get a placeholder weather response.
        
        Returns:
            Weather placeholder response.
        """
        return "I don't have real-time weather data access. To get accurate weather information, please check a weather service or app." 