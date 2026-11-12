# Changelog

All notable changes to AJD will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-10-17 (Ready for Release)

### Added
- One-command deployment via `curl | bash` (macOS + Linux)
- Generic project schema (`projects.example.json`) for user-defined jobs
- AI agent configuration guide (`AGENTS.md`)
- Manual setup instructions (`SETUP.md`)
- Docker support via `Dockerfile` and `docker-compose.yml`

### Changed
- Renamed from "總管監控台" to **AJD** (AI Agents Job Dashboard)
- Replaced hardcoded references with generic `$AJD_HOME` paths
- Removed all personal traces from kk's private dashboard

### Fixed
- Generic service health check via HTTP port status code checks
- Heartbeat API endpoint responses (POST 200/GET 405)
- Private data removal validation (grep scan: 0 matches for private traces)

## [0.4.0] - 2026-09-xx

### Added
- Basic project registry support
- Daily report job tracking
- Stock summary automation

---

Version: 0.5.0
