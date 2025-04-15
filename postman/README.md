# LlamaSearch API - Postman Collection

This directory contains a comprehensive Postman collection for testing and interacting with the LlamaSearch API. The collection is designed to make API testing simple while providing a complete reference for all available endpoints.

## Contents

- `LlamaSearch_API_Collection.json` - The main Postman collection file containing all endpoints
- `LlamaSearch_Environments.json` - Development environment configuration
- `LlamaSearch_Staging_Environment.json` - Staging environment configuration
- `LlamaSearch_Production_Environment.json` - Production environment configuration

## Getting Started

### Importing the Collection

1. Open Postman
2. Click "Import" in the top left
3. Select the `LlamaSearch_API_Collection.json` file
4. Import the environment files as well

### Setting Up Environments

The collection comes with three environments:

- **Development**: For local testing (`http://localhost:8000`)
- **Staging**: For testing on the staging server (`https://staging-api.llamasearch.ai`)
- **Production**: For the production API (`https://api.llamasearch.ai`)

To use an environment:

1. In Postman, click the environments dropdown in the top right
2. Select the desired environment
3. Update any required variables (especially credentials)

### Authentication

Most endpoints require authentication. The collection is set up to automatically capture and store authentication tokens:

1. First, use the "Get API Token" request under the Authentication folder
2. The collection uses a script to automatically save the returned token as an environment variable
3. All other requests will automatically use this token

## Request Categories

### Authentication
- **Get API Token**: Authenticate and retrieve access tokens
- **Refresh Token**: Refresh an expired token
- **Revoke Token**: Revoke an active token

### Search
- **Basic Search**: Simple search across all providers
- **Advanced Search**: Detailed search with filtering options
- **Provider-Specific Search**: Search using a specific provider
- **Semantic Search**: Vector-based semantic search

### RAG (Retrieval-Augmented Generation)
- **Generate Answer**: AI-generated answers using search results as context
- **Document Search & Extract**: Extract information from specific documents
- **Research Assistant**: Generate comprehensive research reports

### Documents
- **Upload Document**: Upload documents for indexing
- **List Documents**: View all uploaded documents
- **Get Document**: Retrieve specific document details
- **Delete Document**: Remove a document

### User Management
- **Register User**: Create a new user account
- **Get Current User**: Retrieve current user information
- **Update User**: Modify user profile
- **Change Password**: Update user password

### Search History
- **Get Search History**: View past searches
- **Clear Search History**: Remove search history
- **Get Search Insights**: Analyze search patterns

### System
- **Get API Status**: Check API availability
- **Get Providers Status**: Verify search provider status
- **Get API Documentation**: Access OpenAPI documentation

## Using Variables

The collection uses Postman variables to make testing easier:

- `{{base_url}}`: The API base URL (set by the environment)
- `{{query}}`: Default search query
- `{{access_token}}`: Authentication token (automatically set after login)
- `{{provider}}`: Search provider name

You can edit these variables in the environment settings or override them in individual requests.

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| base_url | API base URL | http://localhost:8000 |
| username | Login username | testuser |
| password | Login password | testpassword |
| access_token | JWT token | eyJhbGciOiJ... |
| refresh_token | Refresh token | eyJhbGciOiJ... |
| query | Default search query | artificial intelligence research |
| provider | Default search provider | google |
| document_id | Test document ID | doc123 |
| research_question | Example research question | What are the latest advancements in quantum computing? |
| context | Search context | I'm researching the latest developments in AI |

## Test Scripts

The collection includes automated tests that run after each request:

- Status code validation
- Response time checks
- Content type verification
- Token capture and storage

## Workflow Examples

### Basic Search Workflow

1. Use "Get API Token" to authenticate
2. Use "Basic Search" to perform a search
3. Use "Get Search History" to verify the search was recorded

### Document Management Workflow

1. Use "Get API Token" to authenticate
2. Use "Upload Document" to add a document
3. Use "List Documents" to verify the upload
4. Use "Get Document" to retrieve details
5. Use "Delete Document" to remove it

### RAG Research Workflow

1. Use "Get API Token" to authenticate
2. Use "Research Assistant" to generate a research report
3. Use "Get Search History" to see the underlying searches

## API Reference

For a complete API reference, use the "Get API Documentation" endpoint which returns the OpenAPI specification.

## Support

For issues or questions about this Postman collection, please contact:

- Contact: nikjois@llamasearch.ai
- GitHub: https://github.com/llamasearchai

## License

This Postman collection is licensed under the MIT License. See the LICENSE file for details.

---

© 2024 LlamaSearch.ai 