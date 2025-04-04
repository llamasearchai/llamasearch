"""
Base agent classes for LlamaFind Ultra.

This module provides the base classes for agents in LlamaFind Ultra,
including the Agent abstract base class and related data classes.
"""

import logging
import time
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Union

from ..core.model import Model

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("llamafind.agents")

@dataclass
class AgentConfig:
    """Configuration for an agent.
    
    Attributes:
        name: Name of the agent.
        description: Description of the agent.
        agent_type: Type of agent (e.g., "search", "chat", "finance").
        capabilities: List of capabilities offered by the agent.
        model_name: Name of the model to use.
        params: Additional parameters for the agent.
    """
    
    name: str
    description: str = "Agent configuration"
    agent_type: str = "base"
    capabilities: List[str] = field(default_factory=list)
    model_name: Optional[str] = None
    params: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert the configuration to a dictionary.
        
        Returns:
            Dictionary representation of the configuration.
        """
        return {k: v for k, v in self.__dict__.items() if not k.startswith("_")}


@dataclass
class AgentMessage:
    """Message sent to or received from an agent.
    
    Attributes:
        content: Content of the message.
        message_type: Type of message (e.g., "user", "agent", "system").
        message_id: Unique ID of the message.
        timestamp: Timestamp of the message.
        metadata: Additional metadata about the message.
    """
    
    content: str
    message_type: str = "user"
    message_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    timestamp: float = field(default_factory=time.time)
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert the message to a dictionary.
        
        Returns:
            Dictionary representation of the message.
        """
        return {k: v for k, v in self.__dict__.items() if not k.startswith("_")}


@dataclass
class AgentResponse:
    """Response from an agent.
    
    Attributes:
        content: Content of the response.
        agent_type: Type of agent that generated the response.
        message_id: ID of the message that this is a response to.
        response_id: Unique ID of the response.
        timestamp: Timestamp of the response.
        metadata: Additional metadata about the response.
    """
    
    content: str
    agent_type: str
    message_id: str
    response_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    timestamp: float = field(default_factory=time.time)
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert the response to a dictionary.
        
        Returns:
            Dictionary representation of the response.
        """
        return {k: v for k, v in self.__dict__.items() if not k.startswith("_")}


class Agent(ABC):
    """Base class for all agents in LlamaFind Ultra.
    
    This is an abstract base class that defines the interface for all agents
    in LlamaFind Ultra. Concrete implementations should inherit from this
    class and implement its abstract methods.
    """
    
    def __init__(self, config: Union[Dict[str, Any], AgentConfig], model: Optional[Model] = None):
        """Initialize the agent.
        
        Args:
            config: Agent configuration, either as a dictionary or an AgentConfig instance.
            model: Model to use for agent responses. If None, a model will be loaded based
                on the configuration if needed.
        """
        if isinstance(config, dict):
            self.config = AgentConfig(**config)
        else:
            self.config = config
        
        self.name = self.config.name
        self.agent_type = self.config.agent_type
        self.model = model
        self.conversation_history: List[Union[AgentMessage, AgentResponse]] = []
        self.logger = logging.getLogger(f"llamafind.agents.{self.agent_type}")
    
    @abstractmethod
    def process_message(self, message: Union[str, AgentMessage]) -> AgentResponse:
        """Process a message and generate a response.
        
        Args:
            message: Message to process.
            
        Returns:
            Agent response.
        """
        pass
    
    @abstractmethod
    def create_task(self, description: str) -> str:
        """Create a task for the agent to complete.
        
        Args:
            description: Description of the task.
            
        Returns:
            Task ID.
        """
        pass
    
    @abstractmethod
    def run_task(self, task_id: str) -> Dict[str, Any]:
        """Run a task.
        
        Args:
            task_id: ID of the task to run.
            
        Returns:
            Task result.
        """
        pass
    
    def get_capabilities(self) -> List[str]:
        """Get the capabilities of the agent.
        
        Returns:
            List of capabilities.
        """
        return self.config.capabilities
    
    def get_conversation_history(self) -> List[Dict[str, Any]]:
        """Get the conversation history.
        
        Returns:
            List of messages and responses in the conversation history.
        """
        return [item.to_dict() for item in self.conversation_history]
    
    def _create_message(self, message: Union[str, AgentMessage]) -> AgentMessage:
        """Create an AgentMessage object from a string message if needed.
        
        Args:
            message: Message string or AgentMessage object.
            
        Returns:
            AgentMessage object.
        """
        if isinstance(message, str):
            return AgentMessage(content=message)
        return message
    
    def _add_to_history(self, item: Union[AgentMessage, AgentResponse]) -> None:
        """Add a message or response to the conversation history.
        
        Args:
            item: Message or response to add.
        """
        self.conversation_history.append(item)
    
    def _create_response(self, content: str, message: AgentMessage) -> AgentResponse:
        """Create a response to a message.
        
        Args:
            content: Response content.
            message: Message being responded to.
            
        Returns:
            Agent response.
        """
        response = AgentResponse(
            content=content,
            agent_type=self.agent_type,
            message_id=message.message_id,
        )
        return response 