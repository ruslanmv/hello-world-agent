import asyncio
from fastmcp import Client

# The full URL to the server's MCP endpoint
SERVER_URL = "http://127.0.0.1:8000/mcp/"

async def main():
    """Connects to the server and calls the 'hello' tool."""
    print(f"--- Connecting to server at {SERVER_URL} ---")
    
    # The Client takes the full server URL as the first argument
    client = Client(SERVER_URL)
    
    async with client:
        # Ping the server to ensure it's reachable
        await client.ping()
        print("--- Server is online. ---")

        # Call the 'hello' tool with the name "World"
        print("--- Calling tool 'hello'... ---")
        response = await client.call_tool("hello", {"name": "World"})
        
        # The response is the direct string returned by the tool
        print(f"Server response: {response}")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception as e:
        print(f"--- An error occurred: {e} ---")
        print("--- Please ensure the server is running with 'make start' ---")