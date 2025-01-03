import json
import os
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Request
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import logging

# Import LLM Providers
from llm_providers import (
    GeminiProvider, 
    OpenAIProvider, 
    OllamaProvider, 
    LlamaProvider
)

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Create FastAPI app
app = FastAPI(
    title="Senti AI Backend",
    description="AI-powered conversational backend",
    version="0.1.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://0.0.0.0:8765",  # Local development
        "http://10.0.2.2:8765",   # Android emulator
        "capacitor://localhost",  # Capacitor iOS/Android
        "ionic://localhost",      # Ionic framework
        "*"  # Be cautious with this in production
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize LLM Providers
gemini_provider = GeminiProvider()
openai_provider = OpenAIProvider()
ollama_provider = OllamaProvider()
llama_provider = LlamaProvider()

# Provider selection mapping
llm_providers = {
    'gemini': gemini_provider,
    'openai': openai_provider,
    'ollama': ollama_provider,
    'llama': llama_provider
}

@app.get("/ai")
async def read_ai():
    return {"message": "This is the AI endpoint."}

# Change this endpoint to match your client's connection path
@app.websocket("/")  # Change from "/ai" to "/"
async def websocket_endpoint(websocket: WebSocket):
    logger.info("WebSocket connection attempt received")
    try:
        await websocket.accept()
        logger.info("WebSocket connection accepted")
        
        while True:
            try:
                # Log every step for debugging
                raw_message = await websocket.receive_text()
                logger.info(f"Raw message received: {raw_message}")
                
                data = json.loads(raw_message)
                logger.info(f"Parsed data: {data}")
                
                # Extract the type and message
                msg_type = data.get('type')
                message = data.get('message', '')
                
                logger.info(f"Message type: {msg_type}, Content: {message}")

                if msg_type == 'chat_message':
                    # Get the appropriate provider
                    provider_name = data.get('model', 'gemini')
                    provider = llm_providers.get(provider_name, gemini_provider)
                    
                    try:
                        # Generate AI response
                        response = await provider.generate_response(
                            text=message,
                            session_memory=[],
                            sentiment=None
                        )
                        logger.info(f"Generated response: {response[:100]}...")  # Log first 100 chars
                        
                        # Send response back to client
                        await websocket.send_json({
                            "type": "chat_response",
                            "response": response,
                            "model": provider_name
                        })
                        logger.info("Response sent to client")
                        
                    except Exception as e:
                        logger.error(f"Error generating response: {e}")
                        await websocket.send_json({
                            "type": "error",
                            "error": str(e)
                        })
                
            except json.JSONDecodeError as e:
                logger.error(f"JSON decode error: {e}")
                await websocket.send_json({
                    "type": "error",
                    "error": "Invalid JSON format"
                })
            except Exception as e:
                logger.error(f"Unexpected error: {e}")
                await websocket.send_json({
                    "type": "error",
                    "error": str(e)
                })
    
    except WebSocketDisconnect:
        logger.info("Client disconnected")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")

# Optional: Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# Ensure the app is the last thing defined
# This is crucial for ASGI server to find the app
if __name__ == "__main__":
    logger.info("Starting server...")
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8765, log_level="info")
