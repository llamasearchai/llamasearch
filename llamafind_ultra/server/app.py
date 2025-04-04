"""
FastAPI server for LlamaFind Ultra.

This module provides the API server implementation for LlamaFind Ultra
using FastAPI.
"""

import logging
import os
import time
import uuid
from typing import Dict, List, Any, Optional

import uvicorn
from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from ..core.config import load_config, Config
from ..agents.search_agent import SearchAgent
from ..agents.chat_agent import ChatAgent
from ..agents.finance_agent import FinanceAgent
from ..agents import AgentConfig

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("llamafind.server")

# Load configuration
config = load_config()

# Create FastAPI app
app = FastAPI(
    title=config.app_name,
    description="Advanced search platform with AI research capabilities",
    version=config.version,
    docs_url="/docs",
    redoc_url="/redoc",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage for agents and tasks
agents = {
    "search": {
        "type": "search",
        "name": "Search Agent",
        "description": "Agent for performing web searches",
        "capabilities": ["web_search", "news_search"],
    },
    "chat": {
        "type": "chat",
        "name": "Chat Agent",
        "description": "Agent for conversational interactions",
        "capabilities": ["get_current_time", "get_weather"],
    },
    "finance": {
        "type": "finance",
        "name": "Finance Agent",
        "description": "Agent for financial information",
        "capabilities": ["get_stock_info", "get_stock_price", "get_stock_change"],
    },
}

tasks = {}

# Pydantic models for request/response validation
class MessageRequest(BaseModel):
    """Request model for sending a message to an agent."""
    message: str = Field(..., description="Message content")
    
class MessageResponse(BaseModel):
    """Response model for a message."""
    content: str = Field(..., description="Response content")
    timestamp: float = Field(..., description="Response timestamp")
    
class TaskRequest(BaseModel):
    """Request model for creating a task."""
    description: str = Field(..., description="Task description")
    
class TaskResponse(BaseModel):
    """Response model for a task."""
    id: str = Field(..., description="Task ID")
    agent_type: str = Field(..., description="Agent type")
    description: str = Field(..., description="Task description")
    status: str = Field(..., description="Task status")
    created_at: float = Field(..., description="Creation timestamp")
    updated_at: float = Field(..., description="Last update timestamp")
    result: Optional[Dict[str, Any]] = Field(None, description="Task result")
    error: Optional[str] = Field(None, description="Error message, if any")

# Dependency for config access
def get_config():
    """Get the application configuration.
    
    Returns:
        Application configuration.
    """
    return config

# Initialize agent instances
agent_instances = {}

def init_agents():
    """Initialize agent instances."""
    global agent_instances
    
    # Create search agent
    search_config = AgentConfig(
        name="Search Agent",
        description="Agent for performing web searches",
        agent_type="search",
        capabilities=["web_search", "news_search"]
    )
    agent_instances["search"] = SearchAgent(search_config)
    
    # Create chat agent
    chat_config = AgentConfig(
        name="Chat Agent",
        description="Agent for conversational interactions",
        agent_type="chat",
        capabilities=["get_current_time", "get_weather"],
        model_name=config.models.get("default")
    )
    agent_instances["chat"] = ChatAgent(chat_config)
    
    # Create finance agent
    finance_config = AgentConfig(
        name="Finance Agent",
        description="Agent for financial information",
        agent_type="finance",
        capabilities=["get_stock_info", "get_stock_price", "get_stock_change"]
    )
    agent_instances["finance"] = FinanceAgent(finance_config)
    
    logger.info(f"Initialized {len(agent_instances)} agent instances")

# Initialize agents on startup
@app.on_event("startup")
async def startup_event():
    """Initialize resources on startup."""
    init_agents()

# Routes
@app.get("/api/health")
def health_check(config: Config = Depends(get_config)):
    """Health check endpoint.
    
    Returns:
        JSON response with health status
    """
    logger.info("Health check request received")
    return {
        "status": "ok",
        "message": f"{config.app_name} API is running (v{config.version})",
        "version": config.version,
    }

@app.get("/api/agents")
def list_agents():
    """List available agents.
    
    Returns:
        JSON response with available agents
    """
    logger.info("Agents list request received")
    return list(agents.values())

@app.post("/api/agents/{agent_type}/message", response_model=MessageResponse)
def agent_message(agent_type: str, request: MessageRequest):
    """Send a message to an agent.
    
    Args:
        agent_type: Agent type
        request: Message request
        
    Returns:
        Agent response
        
    Raises:
        HTTPException: If agent not found or message is invalid
    """
    logger.info(f"Message request received for agent: {agent_type}")
    
    # Check if agent exists
    if agent_type not in agents:
        logger.error(f"Agent not found: {agent_type}")
        raise HTTPException(status_code=404, detail=f"Agent not found: {agent_type}")
    
    message = request.message
    logger.info(f"Message content: {message}")
    
    try:
        # Use agent instance if available
        if agent_type in agent_instances:
            agent = agent_instances[agent_type]
            agent_response = agent.process_message(message)
            response = MessageResponse(
                content=agent_response.content,
                timestamp=agent_response.timestamp
            )
        else:
            # Fallback to mock responses
            if agent_type == "chat":
                response = MessageResponse(
                    content=f"Hello! I'm the Chat Agent. You said: {message}",
                    timestamp=time.time(),
                )
            elif agent_type == "search":
                response = MessageResponse(
                    content=f"I'll search for: {message}",
                    timestamp=time.time(),
                )
            elif agent_type == "finance":
                response = MessageResponse(
                    content=f"I'll look up financial information for: {message}",
                    timestamp=time.time(),
                )
            else:
                response = MessageResponse(
                    content=f"Agent {agent_type} received: {message}",
                    timestamp=time.time(),
                )
        
        return response
        
    except Exception as e:
        logger.error(f"Error processing message: {e}")
        raise HTTPException(status_code=500, detail=f"Error processing message: {str(e)}")

@app.post("/api/agents/{agent_type}/tasks", response_model=TaskResponse)
def create_task(agent_type: str, request: TaskRequest):
    """Create a task for an agent.
    
    Args:
        agent_type: Agent type
        request: Task request
        
    Returns:
        Created task
        
    Raises:
        HTTPException: If agent not found or task request is invalid
    """
    logger.info(f"Task creation request received for agent: {agent_type}")
    
    # Check if agent exists
    if agent_type not in agents:
        logger.error(f"Agent not found: {agent_type}")
        raise HTTPException(status_code=404, detail=f"Agent not found: {agent_type}")
    
    description = request.description
    logger.info(f"Task description: {description}")
    
    try:
        # Use agent instance if available
        if agent_type in agent_instances:
            agent = agent_instances[agent_type]
            task_id = agent.create_task(description)
            task_data = agent.tasks[task_id]
            
            task = TaskResponse(
                id=task_id,
                agent_type=agent_type,
                description=description,
                status=task_data["status"],
                created_at=task_data["created_at"],
                updated_at=task_data["updated_at"],
                result=task_data["result"],
                error=task_data["error"]
            )
        else:
            # Fallback to original implementation
            timestamp = int(time.time())
            task_id = f"task_{timestamp}_{len(tasks)}"
            
            task = TaskResponse(
                id=task_id,
                agent_type=agent_type,
                description=description,
                status="created",
                created_at=time.time(),
                updated_at=time.time(),
                result=None,
                error=None,
            )
            
            # Store the task
            tasks[task_id] = task.dict()
        
        logger.info(f"Task created with ID: {task.id}")
        return task
        
    except Exception as e:
        logger.error(f"Error creating task: {e}")
        raise HTTPException(status_code=500, detail=f"Error creating task: {str(e)}")

@app.get("/api/agents/{agent_type}/tasks/{task_id}", response_model=TaskResponse)
def get_task(agent_type: str, task_id: str):
    """Get a task by ID.
    
    Args:
        agent_type: Agent type
        task_id: Task ID
        
    Returns:
        Task
        
    Raises:
        HTTPException: If agent or task not found
    """
    logger.info(f"Task retrieval request received for agent: {agent_type}, task: {task_id}")
    
    # Check if agent exists
    if agent_type not in agents:
        logger.error(f"Agent not found: {agent_type}")
        raise HTTPException(status_code=404, detail=f"Agent not found: {agent_type}")
    
    # Check if task exists
    if task_id not in tasks:
        logger.error(f"Task not found: {task_id}")
        raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
    
    # Check if task belongs to agent
    task = tasks[task_id]
    if task["agent_type"] != agent_type:
        logger.error(f"Task {task_id} does not belong to agent {agent_type}")
        raise HTTPException(status_code=404, detail=f"Task {task_id} does not belong to agent {agent_type}")
    
    return TaskResponse(**task)

@app.post("/api/agents/{agent_type}/tasks/{task_id}/run", response_model=TaskResponse)
def run_task(agent_type: str, task_id: str):
    """Run a task.
    
    Args:
        agent_type: Agent type
        task_id: Task ID
        
    Returns:
        Task with result
        
    Raises:
        HTTPException: If agent or task not found
    """
    logger.info(f"Task execution request received for agent: {agent_type}, task: {task_id}")
    
    # Check if agent exists
    if agent_type not in agents:
        logger.error(f"Agent not found: {agent_type}")
        raise HTTPException(status_code=404, detail=f"Agent not found: {agent_type}")
    
    try:
        # Use agent instance if available
        if agent_type in agent_instances:
            agent = agent_instances[agent_type]
            
            # Check if task exists in agent's tasks
            if task_id not in agent.tasks:
                logger.error(f"Task not found: {task_id}")
                raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
            
            # Run the task
            task_data = agent.run_task(task_id)
            
            # Convert to response model
            task = TaskResponse(
                id=task_id,
                agent_type=agent_type,
                description=task_data["description"],
                status=task_data["status"],
                created_at=task_data["created_at"],
                updated_at=task_data["updated_at"],
                result=task_data["result"],
                error=task_data["error"]
            )
            
            return task
            
        else:
            # Fallback to original implementation
            # Check if task exists
            if task_id not in tasks:
                logger.error(f"Task not found: {task_id}")
                raise HTTPException(status_code=404, detail=f"Task not found: {task_id}")
            
            # Check if task belongs to agent
            task = tasks[task_id]
            if task["agent_type"] != agent_type:
                logger.error(f"Task {task_id} does not belong to agent {agent_type}")
                raise HTTPException(status_code=404, detail=f"Task {task_id} does not belong to agent {agent_type}")
            
            # Update task status
            task["status"] = "running"
            task["updated_at"] = time.time()
            logger.info(f"Running task: {task_id}")
            
            # Process the task based on agent type
            try:
                if agent_type == "chat":
                    # Simulate chat processing
                    task["result"] = {
                        "content": f"I've processed your request: {task['description']}",
                        "timestamp": time.time(),
                    }
                elif agent_type == "search":
                    # Simulate search processing
                    task["result"] = {
                        "content": f"Search results for: {task['description']}",
                        "timestamp": time.time(),
                        "results": [
                            {"title": "Example Result 1", "url": "https://example.com/1"},
                            {"title": "Example Result 2", "url": "https://example.com/2"},
                        ],
                    }
                elif agent_type == "finance":
                    # Simulate finance processing
                    task["result"] = {
                        "content": f"Financial information for: {task['description']}",
                        "timestamp": time.time(),
                        "data": {"price": 123.45, "change": 1.23, "percentage": "1.01%"},
                    }
                
                task["status"] = "completed"
                
            except Exception as e:
                logger.error(f"Error running task {task_id}: {e}")
                task["status"] = "failed"
                task["error"] = str(e)
            
            task["updated_at"] = time.time()
            tasks[task_id] = task
            
            return TaskResponse(**task)
            
    except Exception as e:
        logger.error(f"Error running task: {e}")
        raise HTTPException(status_code=500, detail=f"Error running task: {str(e)}")

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler.
    
    Args:
        request: Request that caused the exception
        exc: Exception
        
    Returns:
        JSON response with error details
    """
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "message": str(exc)},
    )

def run_server(host: str = "127.0.0.1", port: int = 8000):
    """Run the API server.
    
    Args:
        host: Host to bind to
        port: Port to bind to
    """
    logger.info(f"Starting {config.app_name} API server on http://{host}:{port}")
    uvicorn.run(app, host=host, port=port) 