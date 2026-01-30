# Executor Service

Isolated Python code execution service for bugdrill.

## Features

- **Secure Isolation**: Runs user code in Docker containers with no network access
- **Resource Limits**: 128MB memory, 0.5 CPU cores, 10-second timeout
- **Python Support**: Python 3.11 Alpine
- **JSON API**: Simple REST API for code execution

## Architecture

```
API Service → Executor Service → Docker Container (Python)
```

The executor service:
1. Receives code execution requests
2. Spawns isolated Docker container
3. Runs code with strict resource limits
4. Returns stdout, stderr, and exit code

## API

### POST /execute

Execute Python code in isolated container.

**Request:**
```json
{
  "code": "print('Hello, World!')",
  "language": "python",
  "timeout_sec": 10
}
```

**Response:**
```json
{
  "success": true,
  "stdout": "Hello, World!\n",
  "stderr": "",
  "exit_code": 0,
  "execution_time_ms": 245
}
```

## Security

- **No network access**: `--network none`
- **Memory limit**: 128MB
- **CPU limit**: 0.5 cores  
- **No new privileges**: Security hardening
- **Timeout**: 10 seconds default

## Future Enhancements

- [ ] Test case execution
- [ ] Multiple language support
- [ ] Custom input/output handling
- [ ] Better error messages
- [ ] Execution result caching
