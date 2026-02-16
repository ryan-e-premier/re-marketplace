---
description: Manage Docker environment for current feature
argument-hint: [start|stop|restart|logs|ps|down]
---

Manage Docker environment for feature: $ARGUMENTS

## Commands

- `start` - Start Docker containers for this feature
- `stop` - Stop Docker containers (preserves data)
- `restart` - Restart Docker containers
- `seed` - Copy database from main to this feature
- `logs` - Show container logs
- `ps` - Show running containers
- `ports` - Show assigned ports for this feature
- `down` - Stop and remove containers (cleanup)

If no argument, defaults to `start`.

## How It Works

### Port Assignment Strategy

Each worktree gets unique ports to avoid conflicts:

**Calculation:**
- Base ports from main `docker-compose.yml`
- Port offset = hash of feature name % 50 (range: 0-49)
- Actual port = base_port + offset

**Example:**
- Main app runs on: 3000, 5432, 6379
- Feature "add-user-profiles" (hash → offset 7):
  - App: 3007
  - DB: 5439
  - Redis: 6386
- Feature "fix-checkout-bug" (hash → offset 23):
  - App: 3023
  - DB: 5455
  - Redis: 6402

### Docker Compose Strategy

**Important:** Docker Compose merges port lists rather than replacing them when using override files. This causes port conflicts. Instead, generate a **standalone** `docker-compose.worktree.yml`.

Main project has standard ports in `docker-compose.yml`:
```yaml
version: '3.8'

services:
  app:
    ports:
      - "3000:3000"
    environment:
      - PORT=3000

  db:
    ports:
      - "5432:5432"

  redis:
    ports:
      - "6379:6379"
```

Worktree gets a **complete standalone** `docker-compose.worktree.yml`:
```yaml
version: '3.8'

services:
  app:
    build: .
    container_name: myapp-<feature-name>-app  # Unique container name
    ports:
      - "<calculated>:3000"  # Calculated unique port
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - PORT=3000
      - FEATURE_NAME=<feature-name>

  db:
    image: postgres:15
    container_name: myapp-<feature-name>-db
    ports:
      - "<calculated>:5432"
    volumes:
      - myapp-<feature-name>-db-data:/var/lib/postgresql/data  # Unique volume
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=dev
      - POSTGRES_PASSWORD=dev

  redis:
    image: redis:7-alpine
    container_name: myapp-<feature-name>-redis
    ports:
      - "<calculated>:6379"

volumes:
  myapp-<feature-name>-db-data:  # Feature-specific volume
```

And `.env.docker` with calculated ports:
```
FEATURE_NAME=<feature-name>
APP_PORT=<calculated>
DB_PORT=<calculated>
REDIS_PORT=<calculated>
```

This approach:
- **Copies** the base `docker-compose.yml` structure
- **Replaces** all ports with calculated unique ports
- **Renames** container names to include feature suffix
- **Uses** separate volume names to isolate data
- **Avoids** the list-merge behavior that causes port conflicts

## Workflow

### 1. Generate standalone Docker compose file

On first run:
- Calculate port offset from feature name
- Read main `docker-compose.yml`
- Generate `docker-compose.worktree.yml` with:
  - All ports replaced with calculated unique ports
  - Container names suffixed with feature name
  - Volume names suffixed with feature name
- Create `.env.docker` with ports
- Show assigned ports to user

### 2. Start containers

```bash
docker-compose -f docker-compose.worktree.yml up -d
```

### 3. Seed database (optional but recommended)

After starting containers, seed from main:
```bash
/feature-docker seed
```

This copies data from main's database so you start with realistic test data:
- User accounts
- Reference data
- Sample content
- Configuration

### 4. Display info

```
✓ Docker containers started for feature: dark-mode

Access your app at:
  App:   http://localhost:3007
  DB:    localhost:5439
  Redis: localhost:6386

Database is empty. To seed from main:
  /feature-docker seed

To view logs:  /feature-docker logs
To stop:       /feature-docker stop
To cleanup:    /feature-docker down
```

## Port Collision Handling

If calculated port is already in use:
1. Try next port (+1, +2, +3...)
2. Max 10 attempts
3. Show error if all ports in range are taken

Keep a registry in main's `.docker-ports.json`:
```json
{
  "dark-mode": {
    "app": 3007,
    "db": 5439,
    "redis": 6386
  },
  "email-notifications": {
    "app": 3023,
    "db": 5455,
    "redis": 6402
  }
}
```

## Commands Implementation

### start
```bash
# Generate docker-compose.worktree.yml if needed
# docker-compose -f docker-compose.worktree.yml up -d
# Show access URLs
```

### stop
```bash
# docker-compose -f docker-compose.worktree.yml stop
# Containers stopped, data preserved
```

### restart
```bash
# docker-compose -f docker-compose.worktree.yml restart
```

### seed
```bash
# Seed feature database from main development database
# This copies data so you start with realistic test data

# Process:
# 1. Detect main database type (PostgreSQL, MySQL, MongoDB, etc.)
# 2. Get main database connection (port 5432 for standard setup)
# 3. Get feature database connection (port 5439 from .env.docker)
# 4. Dump from main, restore to feature

# PostgreSQL example:
pg_dump -h localhost -p 5432 -U dev -d myapp_dev --clean --if-exists | \
  psql -h localhost -p 5439 -U dev -d myapp_dev

# OR using docker-compose:
# In main directory
docker-compose exec db pg_dump -U dev myapp_dev > /tmp/db_dump.sql

# In feature worktree
docker-compose -f docker-compose.worktree.yml exec -T db psql -U dev myapp_dev < /tmp/db_dump.sql

# MySQL:
# mysqldump -h localhost -P 3306 -u dev myapp_dev | \
#   mysql -h localhost -P 3307 -u dev myapp_dev

# MongoDB:
# mongodump --host localhost:27017 --out /tmp/dump
# mongorestore --host localhost:27018 /tmp/dump

# Show result:
# ✓ Database seeded from main
# Tables copied: 25
# Approximate rows: 15,432
```

### logs
```bash
# docker-compose -f docker-compose.worktree.yml logs -f --tail=100
# Follow logs from all services
```

### ps
```bash
# docker-compose -f docker-compose.worktree.yml ps
# Show status of all containers
```

### down
```bash
# docker-compose -f docker-compose.worktree.yml down -v
# Stop and remove containers + volumes
# Warning: This removes data!
```

### ports
```bash
# Show assigned ports from .env.docker
```

## Multi-Service Support

Automatically detects services in `docker-compose.yml`:
- Web apps (3000+)
- Databases (5432+)
- Redis/cache (6379+)
- Other services (8000+)

Generates port mappings for all services found.

## Integration with Workflow

### In feature-prep
Add optional flag: `/feature-prep --docker` or `/feature-prep -d`
- Creates worktree
- Automatically runs `/feature-docker start`
- Shows ports in output

### In feature-build
Remind user: "Docker running at http://localhost:3007"

### In feature-end
Before merging:
- Stop Docker containers
- Optionally cleanup volumes

## Volume Management

Each feature can use:
- **Shared volumes** (symlinked from main) - for common data
- **Isolated volumes** (feature-specific) - for test data

Default strategy:
- Development DBs: isolated (each feature has own DB)
- File uploads: isolated (each feature has own uploads)
- Cache: isolated (independent Redis per feature)

## Environment Variables

Merge multiple env sources:
1. Main `.env` (symlinked)
2. `.env.docker` (generated, feature-specific)
3. Precedence: .env.docker overrides .env

## Database Migrations

Run migrations in isolated feature DB:
```bash
/feature-docker start
# Then run your project's migration command against the feature DB
```

## Testing Strategy

```bash
# Start feature environment
/feature-docker start

# Run your project's test suite against feature DB

# Cleanup test data
/feature-docker restart
```

## Resource Cleanup

Show warning if too many feature containers running:
```
⚠️ Warning: 5 feature environments are running
This may use significant resources (CPU/memory/disk)

Currently running:
- dark-mode (ports: 3007, 5439, 6386)
- email-notifications (ports: 3023, 5455, 6402)
- user-settings (ports: 3031, 5463, 6410)
- performance-improvements (ports: 3042, 5474, 6421)
- refactor-auth (ports: 3015, 5447, 6394)

To stop unused features:
1. Switch to feature worktree
2. Run: /feature-docker down
```

## Docker Compose Requirements

Expects base `docker-compose.yml` in main with:
- Service definitions
- Build context
- Base configuration
- **Standard ports** (worktrees will generate standalone file with unique ports)

Example main `docker-compose.yml`:
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development

  db:
    image: postgres:15
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=dev
      - POSTGRES_PASSWORD=dev

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

**Main project runs normally:**
```bash
# In main directory
docker-compose up
# → App on 3000, DB on 5432, Redis on 6379
```

**Worktrees use standalone file:**
```bash
# In worktree
/feature-docker start
# → Generates docker-compose.worktree.yml with unique ports
# → App on 3007, DB on 5439, Redis on 6386 (no conflict!)
```

## Advanced: Custom Services

If feature needs additional services:
1. Edit `docker-compose.worktree.yml` in worktree
2. Add custom services with unique ports
3. Update `.env.docker` with new ports

Example: Feature needs Elasticsearch
```yaml
# In worktree's docker-compose.worktree.yml
services:
  elasticsearch:
    image: elasticsearch:8
    container_name: myapp-<feature-name>-elasticsearch
    ports:
      - "<calculated>:9200"  # Unique port for this feature
    environment:
      - discovery.type=single-node
```

## Error Handling

**Docker not running:**
```
Error: Docker daemon not running
Please start Docker Desktop and try again
```

**Port already in use:**
```
Error: Port 3007 is already in use
Trying alternative port: 3008...
✓ Using port 3008
```

**No docker-compose.yml in main:**
```
Error: No docker-compose.yml found in main project
This command requires a Docker Compose configuration
```

**Services failed to start:**
```
Error: Some services failed to start
Run: /feature-docker logs
To see error details
```

## Best Practices

1. **Stop unused containers** - Free up resources when not actively working
2. **Use `down` between major changes** - Clean slate for fresh testing
3. **Don't commit worktree files** - They're feature-specific (add to .gitignore)
4. **Check ports** - Run `/feature-docker ports` to see your URLs
5. **Monitor resources** - Use `docker stats` if system gets slow

## Files Created

In each worktree:
- `docker-compose.worktree.yml` - Complete standalone config (not an override)
- `.env.docker` - Calculated ports and feature name

Added to main (or `.gitignore`):
- `.docker-ports.json` - Global port registry

## Extensions
Check for `.claude/claudeflow-extensions/feature-docker.md`. If it exists, read it and incorporate any additional instructions, template sections, or workflow modifications.

## Important Notes

- Worktree files should NOT be committed (add `docker-compose.worktree.yml` to `.gitignore`)
- Each feature gets completely isolated environment
- Data is ephemeral by default (use `down` to clean up)
- Main `docker-compose.yml` has standard ports, worktrees use standalone file with unique ports
- Worktrees share Docker images (built once, used everywhere)
- Main project runs normally on standard ports (3000, 5432, etc.)
- No interference between main and worktree environments

## Frontend Environment

For frontend frameworks that bake environment variables at build/dev-server startup (like Vite), you may need to create local env files with updated API URLs pointing to worktree ports. This is stack-specific and should be handled via extensions. See `.claude/claudeflow-extensions/feature-docker.md`.
