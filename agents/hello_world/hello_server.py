from fastmcp import FastMCP

# Create a FastMCP server instance
doc = FastMCP(name="Hello World Server")

@doc.tool
def hello(name: str) -> str:
    """Return a simple greeting to the provided name."""
    return f"Hello, {name}!"

if __name__ == "__main__":
    # Launch the server over HTTP transport on localhost:8000
    doc.run(
        transport="http",
        host="127.0.0.1",
        port=8000,
    )