# Changelog

All notable changes to AJD will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Heartbeat mechanism for real-time job failure detection
- Generic adapter layer for multiple scheduler types (crontab, launchd, systemd, Hermes)
- AI agent setup guide (`AGENTS.md`) for automatic configuration

### Changed
- Refactored private dashboard into generic engine with template projects

## [0.5.0] - 2026-10-17

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
- Generic service health check via HTTP port status
- Heartbeat API endpoint consistency

## [0.4.0] - 2026-09-xx

### Added
- Basic project registry support
- Daily report job tracking
- Stock summary automation

---

Version: 0.5.0
