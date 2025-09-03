# Changelog

## [0.1.1] - 2024-09-03

### Fixed
- **Critical**: Fixed intermittent empty image generation in production environments
- **Critical**: Replaced `Port.open` with `System.cmd` for better reliability
- **Critical**: Added robust GIF header detection for parsing
- **Critical**: Added message clearing to prevent stale data issues

### Added
- Enhanced error handling with detailed error messages
- Custom timeout support via `Captcha.get(timeout)`
- Better documentation and examples
- Production environment compatibility improvements

### Changed
- **Breaking**: `Captcha.get()` now uses `System.cmd` internally instead of `Port.open`
- **Breaking**: Improved error return format for better debugging
- **Breaking**: Added timeout parameter support
- **Breaking**: Changed default timeout from 1 second to 2 seconds

## [0.1.0] - Original Release

### Added
- Initial release of elixir-captcha library
- Basic captcha generation using C binary
- Port-based communication with external binary
