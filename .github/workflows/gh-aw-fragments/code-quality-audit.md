## Code Quality Audit Patterns

### Complexity Indicators

**High Priority (>100 lines, >3 nesting):**
- Functions exceeding 100 lines
- Classes with more than 10 methods
- Files exceeding 500 lines
- Nesting depth greater than 4 levels
- Cyclomatic complexity >10

**Medium Priority:**
- Functions 50-100 lines
- Repeated switch/match over same enum
- Long parameter lists (>5 parameters)
- Complex boolean expressions needing names

### Duplication Patterns

**High Priority:**
- Identical functions >10 lines
- Copy-pasted validation logic
- Repeated error handling patterns
- Similar helper functions doing same thing differently

**Medium Priority:**
- Similar string/formatting logic
- Duplicate config parsing
- Repeated data transformations

### Dead Code Patterns

- Unused exported functions
- Unused imports/modules
- Deprecated API usage
- Commented-out code blocks
- TODO/FIXME comments never addressed
