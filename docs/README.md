# Access Management System - Quick Reference

This quick reference guide provides an overview of the Access Management System for Azure DevOps and Microsoft Partner Network integration with Microsoft 365 Agents SDK.

## Documentation Index

### Getting Started
- **[Getting Started Guide](GETTING_STARTED_ACCESS_MANAGEMENT.md)** - Step-by-step setup instructions
- **[Access Management Overview](ACCESS_MANAGEMENT.md)** - Complete system documentation
- **[Environment Template](.env.template)** - Template for environment variables

### Integration Guides
- **[Azure DevOps Integration](AZURE_DEVOPS_INTEGRATION.md)** - Detailed Azure DevOps integration guide
- **[Microsoft Partner Network Integration](MICROSOFT_PARTNER_NETWORK_INTEGRATION.md)** - Comprehensive MPN integration guide

### Configuration
- **[Configuration Schema](access-management-schema.json)** - JSON schema for validation
- **[Azure DevOps Example](access-management.azure-devops.example.json)** - Azure DevOps configuration example
- **[MPN Example](access-management.mpn.example.json)** - Microsoft Partner Network configuration example
- **[Complete Example](access-management.complete.example.json)** - Full configuration with both integrations

## Quick Start Commands

### 1. Setup Environment

```bash
# Copy environment template
cp docs/.env.template .env

# Edit with your credentials
nano .env
```

### 2. Choose Configuration

```bash
# For Azure DevOps only
cp docs/access-management.azure-devops.example.json access-management.json

# For Microsoft Partner Network only
cp docs/access-management.mpn.example.json access-management.json

# For both
cp docs/access-management.complete.example.json access-management.json
```

### 3. Update Configuration

Edit `access-management.json` with your specific settings.

## Key Features

| Feature | Azure DevOps | Microsoft Partner Network |
|---------|--------------|---------------------------|
| Work Item Management | ✅ | ❌ |
| Build Pipelines | ✅ | ❌ |
| Code Repositories | ✅ | ❌ |
| Partner Profile | ❌ | ✅ |
| Customer Management | ❌ | ✅ |
| Benefits Access | ❌ | ✅ |
| Usage Analytics | ❌ | ✅ |
| Token Management | ✅ | ✅ |
| Azure Key Vault | ✅ | ✅ |
| Audit Logging | ✅ | ✅ |

## Authentication Quick Reference

### Azure DevOps

**Personal Access Token (PAT)**
```json
{
  "authentication": {
    "type": "pat",
    "token": "${AZURE_DEVOPS_PAT}"
  }
}
```

**OAuth 2.0**
```json
{
  "authentication": {
    "type": "oauth",
    "clientId": "${AZURE_AD_CLIENT_ID}",
    "clientSecret": "${AZURE_AD_CLIENT_SECRET}",
    "tenantId": "${AZURE_AD_TENANT_ID}"
  }
}
```

### Microsoft Partner Network

```json
{
  "tenantId": "${MPN_TENANT_ID}",
  "clientId": "${MPN_CLIENT_ID}",
  "clientSecret": "${MPN_CLIENT_SECRET}",
  "partnerId": "${MPN_PARTNER_ID}"
}
```

## Common Operations

### Azure DevOps

| Operation | Scope Required |
|-----------|----------------|
| Read work items | `vso.work` |
| Create/update work items | `vso.work_write` |
| View builds | `vso.build` |
| Queue builds | `vso.build_execute` |
| Read code | `vso.code` |
| Create pull requests | `vso.code_write` |

### Microsoft Partner Network

| Operation | Permission Required |
|-----------|---------------------|
| Read partner profile | User impersonation |
| Manage customers | Admin Agent role |
| View benefits | Any partner role |
| Access analytics | Any partner role |

## Security Checklist

- [ ] Store credentials in environment variables or Azure Key Vault
- [ ] Never commit `.env` or `access-management.json` to source control
- [ ] Add these files to `.gitignore`
- [ ] Enable token rotation for production environments
- [ ] Use minimum required scopes/permissions
- [ ] Enable audit logging
- [ ] Implement rate limiting
- [ ] Use HTTPS for all API calls
- [ ] Regularly rotate credentials
- [ ] Monitor access logs for suspicious activity

## Troubleshooting Quick Guide

### Authentication Issues

**Problem**: 401 Unauthorized  
**Check**:
- Token hasn't expired
- Credentials are correct
- Environment variables are loaded

**Problem**: 403 Forbidden  
**Check**:
- User has required permissions
- Correct scopes are configured
- Admin consent granted (MPN)

### Rate Limiting

**Problem**: 429 Too Many Requests  
**Solution**:
- Implement exponential backoff
- Add delays between requests
- Use pagination effectively
- Cache frequently accessed data

### Connection Issues

**Problem**: Network errors  
**Check**:
- API endpoints are correct
- Network connectivity is working
- Firewall rules allow outbound HTTPS
- No proxy issues

## API Endpoints

### Azure DevOps
- Base URL: `https://dev.azure.com/{organization}`
- API Version: `7.0` (or later)
- Documentation: https://docs.microsoft.com/en-us/rest/api/azure/devops/

### Microsoft Partner Network
- Base URL: `https://api.partnercenter.microsoft.com`
- API Version: `v1`
- Documentation: https://docs.microsoft.com/en-us/partner-center/develop/

## Code Examples

### JavaScript/Node.js

See detailed examples in:
- [Azure DevOps Integration Guide](AZURE_DEVOPS_INTEGRATION.md#api-examples)
- [Microsoft Partner Network Integration Guide](MICROSOFT_PARTNER_NETWORK_INTEGRATION.md#api-examples)

### .NET/C#

For C# implementations, refer to the Microsoft 365 Agents SDK for .NET:
- Repository: https://github.com/Microsoft/Agents-for-net
- Documentation: https://learn.microsoft.com/en-us/dotnet/api/?view=m365-agents-sdk

### Python

For Python implementations, refer to the Microsoft 365 Agents SDK for Python:
- Repository: https://github.com/Microsoft/Agents-for-python
- Documentation: https://learn.microsoft.com/en-us/python/api/agent-sdk-python/agents-overview

## Support and Resources

### Documentation
- [Microsoft 365 Agents SDK Documentation](https://aka.ms/M365-Agents-SDK-Docs)
- [Azure DevOps REST API](https://docs.microsoft.com/en-us/rest/api/azure/devops/)
- [Partner Center API](https://docs.microsoft.com/en-us/partner-center/develop/)

### Getting Help
- Open an issue on [GitHub](https://github.com/Microsoft/Agents/issues)
- Check existing documentation in this repository
- Consult Microsoft Learn resources

### Related Resources
- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [OAuth 2.0 Best Practices](https://oauth.net/2/)
- [Azure AD App Registration Guide](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)

## Version History

- **v1.0** (2024-12-26)
  - Initial release
  - Azure DevOps integration support
  - Microsoft Partner Network integration support
  - Comprehensive documentation and examples
  - Security best practices
  - Configuration schema and examples

## License

This project is part of the Microsoft 365 Agents SDK and follows the same licensing terms. See [LICENSE](../LICENSE) for details.
