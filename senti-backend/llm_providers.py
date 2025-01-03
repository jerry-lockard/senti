import os
import base64
import aiohttp
import google.generativeai as genai
import openai
import ollama
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Optional

class BaseLLMProvider(ABC):
    @abstractmethod
    async def generate_response(
        self, 
        text: str, 
        session_memory: Optional[List[Dict[str, Any]]] = None, 
        sentiment: Optional[Dict[str, Any]] = None
    ) -> str:
        pass

    @abstractmethod
    async def analyze_image(self, image_base64: str) -> str:
        pass

class GeminiProvider(BaseLLMProvider):
    def __init__(self):
        # Load API key from environment variable
        api_key = os.getenv('GEMINI_API_KEY', 'YOUR_GEMINI_API_KEY')
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-2.0-flash-exp')
        self.vision_model = genai.GenerativeModel('gemini-pro-vision')

    async def generate_response(
        self, 
        text: str, 
        session_memory: Optional[List[Dict[str, Any]]] = None, 
        sentiment: Optional[Dict[str, Any]] = None
    ) -> str:
        try:
            # Prepare context with session memory and sentiment
            context = text
            if session_memory:
                context = ' '.join([m.get('content', '') for m in session_memory]) + ' ' + text
            
            if sentiment:
                context += f" [Sentiment Context: {sentiment}]"

            # Generate response
            response = await self.model.generate_content_async(context)
            return response.text
        except Exception as e:
            return f"Gemini generation error: {str(e)}"

    async def analyze_image(self, image_base64: str) -> str:
        try:
            # Decode base64 image
            image_data = base64.b64decode(image_base64)
            
            # Analyze image
            response = await self.vision_model.generate_content_async([
                "Describe this image in detail.",
                image_data
            ])
            return response.text
        except Exception as e:
            return f"Gemini image analysis error: {str(e)}"

class OpenAIProvider(BaseLLMProvider):
    def __init__(self):
        # Load API key from environment variable
        openai.api_key = os.getenv('OPENAI_API_KEY')
        self.model = 'gpt-3.5-turbo'

    async def generate_response(
        self, 
        text: str, 
        session_memory: Optional[List[Dict[str, Any]]] = None, 
        sentiment: Optional[Dict[str, Any]] = None
    ) -> str:
        try:
            # Prepare messages for OpenAI
            messages = session_memory or []
            messages.append({"role": "user", "content": text})
            
            # Add sentiment context if available
            if sentiment:
                messages.append({
                    "role": "system", 
                    "content": f"Sentiment Context: {sentiment}"
                })

            # Generate response
            response = await openai.ChatCompletion.acreate(
                model=self.model,
                messages=messages
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"OpenAI generation error: {str(e)}"

    async def analyze_image(self, image_base64: str) -> str:
        try:
            # OpenAI Vision API (if available)
            response = await openai.ChatCompletion.acreate(
                model="gpt-4-vision-preview",
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": "Describe this image in detail."},
                            {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}}
                        ]
                    }
                ]
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"OpenAI image analysis error: {str(e)}"

class OllamaProvider(BaseLLMProvider):
    def __init__(self):
        # Ollama endpoint configuration
        self.endpoint = os.getenv('OLLAMA_ENDPOINT', 'http://localhost:11434/api/chat')
        self.model = os.getenv('OLLAMA_MODEL', 'llama2')

    async def generate_response(
        self, 
        text: str, 
        session_memory: Optional[List[Dict[str, Any]]] = None, 
        sentiment: Optional[Dict[str, Any]] = None
    ) -> str:
        try:
            # Prepare messages for Ollama
            messages = session_memory or []
            messages.append({"role": "user", "content": text})
            
            # Add sentiment context if available
            if sentiment:
                messages.append({
                    "role": "system", 
                    "content": f"Sentiment Context: {sentiment}"
                })

            # Generate response via Ollama
            response = await ollama.AsyncClient().chat(
                model=self.model,
                messages=messages
            )
            return response['message']['content']
        except Exception as e:
            return f"Ollama generation error: {str(e)}"

    async def analyze_image(self, image_base64: str) -> str:
        try:
            # Decode base64 image
            image_data = base64.b64decode(image_base64)
            
            # Analyze image (if Ollama supports vision)
            response = await ollama.AsyncClient().chat(
                model=self.model,
                messages=[
                    {
                        "role": "user", 
                        "content": "Describe this image in detail.",
                        "images": [image_data]
                    }
                ]
            )
            return response['message']['content']
        except Exception as e:
            return f"Ollama image analysis error: {str(e)}"

class LlamaProvider(BaseLLMProvider):
    def __init__(self):
        # Llama endpoint configuration
        self.endpoint = os.getenv('LLAMA_ENDPOINT', 'http://localhost:8000/v1/chat/completions')
        self.model = os.getenv('LLAMA_MODEL', 'llama-2-7b-chat')

    async def generate_response(
        self, 
        text: str, 
        session_memory: Optional[List[Dict[str, Any]]] = None, 
        sentiment: Optional[Dict[str, Any]] = None
    ) -> str:
        try:
            # Prepare messages for Llama
            messages = session_memory or []
            messages.append({"role": "user", "content": text})
            
            # Add sentiment context if available
            if sentiment:
                messages.append({
                    "role": "system", 
                    "content": f"Sentiment Context: {sentiment}"
                })

            # Generate response via Llama API
            async with aiohttp.ClientSession() as session:
                async with session.post(self.endpoint, json={
                    "model": self.model,
                    "messages": messages,
                    "temperature": 0.7
                }) as response:
                    result = await response.json()
                    return result['choices'][0]['message']['content']
        except Exception as e:
            return f"Llama generation error: {str(e)}"

    async def analyze_image(self, image_base64: str) -> str:
        try:
            # Decode base64 image
            image_data = base64.b64decode(image_base64)
            
            # Analyze image (if Llama supports vision)
            async with aiohttp.ClientSession() as session:
                async with session.post(self.endpoint, json={
                    "model": self.model,
                    "messages": [
                        {
                            "role": "user", 
                            "content": "Describe this image in detail.",
                            "images": [image_data]
                        }
                    ]
                }) as response:
                    result = await response.json()
                    return result['choices'][0]['message']['content']
        except Exception as e:
            return f"Llama image analysis error: {str(e)}"
