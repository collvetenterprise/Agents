# Access Management System

This document describes the access management system for integrating Azure DevOps and Microsoft Partner Network with the Microsoft 365 Agents SDK.

## Overview

The Access Management System provides a unified way to manage permissions, credentials, and access controls for your agents when integrating with Azure DevOps and Microsoft Partner Network services.

## Features

- **Azure DevOps Integration**: Seamless integration with Azure DevOps for CI/CD pipelines and work item tracking
- **Microsoft Partner Network Access**: Manage access to Microsoft Partner Network resources and benefits
- **Role-Based Access Control (RBAC)**: Define and manage user roles and permissions
- **Token Management**: Secure handling of authentication tokens and credentials
- **Audit Logging**: Track access and changes for compliance

## Architecture

The access management system consists of several components:

1. **Authentication Provider**: Handles OAuth 2.0 authentication flows
2. **Authorization Service**: Manages permissions and access control
3. **Token Store**: Securely stores and manages access tokens
4. **Audit Logger**: Records access attempts and changes

## Azure DevOps Integration

### Prerequisites

- Azure DevOps organization
- Personal Access Token (PAT) or OAuth app registration
- Appropriate permissions in Azure DevOps

### Configuration

Create a configuration file for Azure DevOps access:

```json
{
  "azureDevOps": {
    "organizationUrl": "https://dev.azure.com/{your-organization}",
    "projectName": "YourProject",
    "authentication": {
      "type": "pat",
      "token": "${AZURE_DEVOPS_PAT}"
    },
    "permissions": {
      "scopes": [
        "vso.work",
        "vso.build",
        "vso.code"
      ]
    }
  }
}
```

### Supported Operations

- **Work Items**: Create, read, update work items
- **Build Pipelines**: Trigger builds, check status
- **Code Repositories**: Access code repositories, create pull requests
- **Release Management**: Manage releases and deployments

### Example Usage

```javascript
// Example: Accessing Azure DevOps from your agent
const azureDevOpsClient = new AzureDevOpsClient({
  organizationUrl: config.azureDevOps.organizationUrl,
  personalAccessToken: process.env.AZURE_DEVOPS_PAT
});

// Query work items
const workItems = await azureDevOpsClient.getWorkItems({
  project: 'YourProject',
  wiql: 'SELECT [System.Id] FROM WorkItems WHERE [System.State] = "Active"'
});
```

## Microsoft Partner Network Integration

### Prerequisites

- Microsoft Partner Network account
- Partner Center credentials
- API access enabled

### Configuration

Create a configuration file for Microsoft Partner Network access:

```json
{
  "microsoftPartnerNetwork": {
    "tenantId": "${MPN_TENANT_ID}",
    "clientId": "${MPN_CLIENT_ID}",
    "clientSecret": "${MPN_CLIENT_SECRET}",
    "partnerId": "${MPN_PARTNER_ID}",
    "authentication": {
      "authority": "https://login.microsoftonline.com/",
      "scopes": [
        "https://api.partnercenter.microsoft.com/user_impersonation"
      ]
    }
  }
}
```

### Supported Operations

- **Partner Profile**: Access partner profile information
- **Customer Management**: Manage customer relationships
- **Benefits**: Access partner benefits and resources
- **Analytics**: Access usage and performance data

### Example Usage

```javascript
// Example: Accessing Microsoft Partner Network from your agent
const mpnClient = new MicrosoftPartnerNetworkClient({
  tenantId: process.env.MPN_TENANT_ID,
  clientId: process.env.MPN_CLIENT_ID,
  clientSecret: process.env.MPN_CLIENT_SECRET
});

// Get partner profile
const profile = await mpnClient.getPartnerProfile();

// Access benefits
const benefits = await mpnClient.getBenefits();
```

## Security Best Practices

### Token Management

1. **Never commit tokens to source control**: Use environment variables or secure vaults
2. **Rotate tokens regularly**: Implement token rotation policies
3. **Use minimum required permissions**: Apply principle of least privilege
4. **Enable token expiration**: Set appropriate token lifetimes

### Access Control

1. **Implement RBAC**: Define roles and assign permissions appropriately
2. **Enable multi-factor authentication**: Require MFA for sensitive operations
3. **Monitor access logs**: Regularly review audit logs
4. **Implement IP restrictions**: Limit access to known IP ranges when possible

### Credential Storage

Use Azure Key Vault or similar secure storage for credentials:

```json
{
  "credentialStore": {
    "type": "azure-keyvault",
    "vaultUrl": "https://{your-vault}.vault.azure.net/",
    "credentials": {
      "azureDevOpsPat": "secret-name-in-vault",
      "mpnClientSecret": "secret-name-in-vault"
    }
  }
}
```

## Access Management Configuration Schema

Complete schema for access management configuration:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Access Management Configuration",
  "type": "object",
  "properties": {
    "azureDevOps": {
      "type": "object",
      "properties": {
        "organizationUrl": { "type": "string" },
        "projectName": { "type": "string" },
        "authentication": {
          "type": "object",
          "properties": {
            "type": { "enum": ["pat", "oauth"] },
            "token": { "type": "string" }
          }
        }
      }
    },
    "microsoftPartnerNetwork": {
      "type": "object",
      "properties": {
        "tenantId": { "type": "string" },
        "clientId": { "type": "string" },
        "clientSecret": { "type": "string" },
        "partnerId": { "type": "string" }
      }
    },
    "credentialStore": {
      "type": "object",
      "properties": {
        "type": { "enum": ["azure-keyvault", "environment", "file"] },
        "vaultUrl": { "type": "string" }
      }
    }
  }
}
```

## Troubleshooting

### Common Issues

#### Authentication Failures

**Problem**: Authentication to Azure DevOps fails  
**Solution**: Verify your PAT is valid and has the required scopes

#### Permission Denied

**Problem**: Operations fail with permission denied errors  
**Solution**: Ensure your account has the necessary permissions in Azure DevOps or Partner Center

#### Token Expiration

**Problem**: Requests fail with expired token errors  
**Solution**: Implement token refresh logic or regenerate tokens

## Additional Resources

- [Azure DevOps API Documentation](https://docs.microsoft.com/en-us/rest/api/azure/devops/)
- [Microsoft Partner Center API](https://docs.microsoft.com/en-us/partner-center/develop/)
- [OAuth 2.0 Best Practices](https://oauth.net/2/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)

## Support

For issues or questions regarding the access management system:

1. Check the [troubleshooting section](#troubleshooting) above
2. Review the [Microsoft 365 Agents SDK documentation](https://aka.ms/M365-Agents-SDK-Docs)
3. Open an issue in the [GitHub repository](https://github.com/Microsoft/Agents)
