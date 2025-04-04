# Contributing to LlamaSearch Secure API Management

Thank you for your interest in contributing to the LlamaSearch Secure API Management system! This document provides guidelines and best practices for contributing to this project.

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Security First

Since this project deals with sensitive API credentials, security is our top priority:

1. **NEVER commit API keys or credentials** to the repository
2. **ALWAYS use our secure API key management tools** for handling credentials
3. **Run security checks** before submitting your contributions
4. **Report security vulnerabilities** privately to the maintainers

## Development Setup

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/your-username/llamasearchai-secure-api-management.git
   cd llamasearchai-secure-api-management
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Install pre-commit hooks:
   ```bash
   pre-commit install
   ```

4. Set up secure API keys for development:
   ```bash
   python setup_api_keys.py
   ```

## Pull Request Process

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following our coding standards

3. Run security checks:
   ```bash
   python check_for_api_keys.py
   ```

4. Run tests:
   ```bash
   python -m unittest discover
   ```

5. Commit your changes with clear, descriptive messages:
   ```bash
   git commit -m "feat: Add new secure key rotation feature"
   ```

6. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

7. Submit a pull request to the `main` branch

## Coding Standards

### General Guidelines

- Follow the [PEP 8](https://pep8.org/) style guide for Python code
- Write clear, descriptive variable and function names
- Add docstrings to all functions and classes
- Keep functions focused on a single responsibility
- Write unit tests for new functionality

### Security-Specific Standards

- Use secure coding practices (input validation, error handling, etc.)
- Never hardcode credentials or secrets
- Use our `llamakeys` library for any API key access
- Prefer environment variables for configuration
- Add appropriate logging (but never log sensitive information)

### Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code changes that neither fix bugs nor add features
- `test`: Adding or updating tests
- `chore`: Changes to the build process or auxiliary tools

## License

By contributing to this project, you agree that your contributions will be licensed under the project's [MIT License](LICENSE). 