## Runtime Setup

Detect and configure language runtimes based on project files present.

### Detection Order

Check for these files in order:

1. **`go.mod`** → Use Go
2. **`Cargo.toml`** → Use Rust
3. **`pyproject.toml`** or **`requirements.txt`** or **`uv.lock`** → Use Python
4. **`package.json`** → Use Node.js
5. **`.python-version`** → Use Python (version from file)
6. **`.nvmrc`** or **`.node-version`** → Use Node.js (version from file)
7. **`.ruby-version`** → Use Ruby

### Setup Commands

When runtime is detected, use appropriate setup:

**Go:**
```
Use actions/setup-go with version from go.mod or latest
```

**Rust:**
```
Use actions/setup-rust or install rustup
```

**Python:**
```
Use actions/setup-python or uv for fast package management
```

**Node.js:**
```
Use actions/setup-node with version from .nvmrc, .node-version, or package.json engines
```

**Ruby:**
```
Use ruby/setup-ruby with version from .ruby-version
```
