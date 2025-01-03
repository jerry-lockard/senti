import os
import json
import logging
import asyncio
import base64
from typing import List, Dict, Any
import google.generativeai as genai
import openai
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette.websockets import WebSocketState

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.connection_count = 0

    async def connect(self, websocket: WebSocket) -> str:
        """Handle a new connection."""
        await websocket.accept()
        connection_id = str(self.connection_count)
        self.active_connections[connection_id] = websocket
        self.connection_count += 1
        return connection_id

    async def disconnect(self, connection_id: str):
        """Disconnect a client."""
        if connection_id in self.active_connections:
            del self.active_connections[connection_id]

    async def send_message(self, connection_id: str, message: str):
        """Send a message to a specific connection."""
        if connection_id in self.active_connections:
            websocket = self.active_connections[connection_id]
            try:
                await websocket.send_text(message)
            except Exception as e:
                logger.error(f"Error sending message: {str(e)}")
                await self.disconnect(connection_id)

class ApiService:
    def __init__(self):
        self.gemini_api_key = os.getenv('GEMINI_API_KEY')
        self.openai_api_key = os.getenv('OPENAI_API_KEY')
        self.ollama_endpoint = os.getenv('OLLAMA_ENDPOINT', 'http://localhost:11434/api/chat')
        self.llama_endpoint = os.getenv('LLAMA_ENDPOINT', 'http://localhost:8000/v1/chat/completions')
        
        self.websocket_url_android = os.getenv('WEBSOCKET_URL_ANDROID')
        self.websocket_url_ios = os.getenv('WEBSOCKET_URL_IOS')
        self.websocket_url_web = os.getenv('WEBSOCKET_URL_WEB')
        self.websocket_url_default = os.getenv('WEBSOCKET_URL_DEFAULT')

        # API Client Setup
        genai.configure(api_key=self.gemini_api_key)
        openai.api_key = self.openai_api_key

    async def _stream_gemini_response(self, response, websocket: WebSocket):
        """Stream Gemini response chunks to the client."""
        try:
            async for chunk in response:
                if chunk.text:
                    await websocket.send_json({
                        "type": "stream",
                        "content": chunk.text,
                        "done": False
                    })

            await websocket.send_json({
                "type": "stream",
                "content": "",
                "done": True
            })
        except Exception as e:
            logger.error(f"Error while streaming Gemini response: {str(e)}")
            await websocket.send_json({
                "type": "error",
                "content": f"Streaming error: {str(e)}"
            })

    async def handle_gemini_stream(self, message: str, history: List[Dict[str, Any]], websocket: WebSocket):
        """Handle streaming responses from Gemini."""
        try:
            model = genai.GenerativeModel('gemini-2.0-flash-exp')
            chat = model.start_chat(history=[{'role': 'user', 'parts': [h['content']]} for h in history])
            
            response = chat.send_message(message, stream=True)
            await self._stream_gemini_response(response, websocket)
            
        except Exception as e:
            logger.error(f"Gemini streaming error: {str(e)}")
            await websocket.send_json({
                "type": "error",
                "content": f"Gemini streaming error: {str(e)}"
            })

# Create instances
app = FastAPI()
manager = ConnectionManager()
api_service = ApiService()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        os.getenv('CORS_ORIGIN_1', 'http://0.0.0.0:8765'),
        os.getenv('CORS_ORIGIN_2', 'http://10.0.2.2:8765'),
        os.getenv('CORS_ORIGIN_3', 'capacitor://localhost'),
        os.getenv('CORS_ORIGIN_4', 'ionic://localhost'),
        "*"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.websocket("/ai")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint to handle incoming messages."""
    connection_id = await manager.connect(websocket)
    
    try:
        while True:
            try:
                data = await websocket.receive_json()
                
                # Extract WebSocket message parameters
                message = data.get('message', '')
                history = data.get('history', [])
                provider = data.get('provider', 'gemini')
                model = data.get('model')
                is_stream = data.get('stream', False)
                is_text_only = data.get('is_text_only', True)
                platform = data.get('platform')
                
                if not message:
                    await websocket.send_json({
                        "type": "error",
                        "content": "Message cannot be empty"
                    })
                    continue

                if is_stream and provider == 'gemini':
                    # Handle streaming response for Gemini
                    await api_service.handle_gemini_stream(message, history, websocket)
                else:
                    # Handle non-streaming response (other providers like OpenAI, Ollama)
                    response = await api_service.send_message(
                        message, history, provider, model, is_text_only
                    )
                    
                    await websocket.send_json({
                        "type": "response",
                        "content": response,
                        "done": True
                    })

            except json.JSONDecodeError:
                await websocket.send_json({
                    "type": "error",
                    "content": "Invalid JSON format"
                })
                
    except WebSocketDisconnect:
        await manager.disconnect(connection_id)
        logger.info(f"Client #{connection_id} disconnected")
        
    except Exception as e:
        logger.error(f"WebSocket error: {str(e)}")
        if websocket.client_state != WebSocketState.DISCONNECTED:
            await websocket.close(code=1001)

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "connections": len(manager.active_connections)
    }

@app.get("/status")
async def get_status():
    """Get status endpoint."""
    return {
        "active_connections": len(manager.active_connections),
        "providers": {
            "gemini": bool(api_service.gemini_api_key),
            "openai": bool(api_service.openai_api_key),
            "ollama": bool(api_service.ollama_endpoint),
            "llama": bool(api_service.llama_endpoint)
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8765)
