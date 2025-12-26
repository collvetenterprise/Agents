# Getting Started with Access Management

This guide will help you set up and configure the Access Management System for Azure DevOps and Microsoft Partner Network integration.

## Quick Start

### Step 1: Prerequisites

Before you begin, ensure you have:

- Node.js 18+ or .NET 8+ or Python 3.10+ (depending on your preferred language)
- An Azure DevOps account with appropriate permissions
- A Microsoft Partner Network account (if using MPN features)
- Access to create service principals or generate personal access tokens

### Step 2: Install Dependencies

#### For Node.js Projects

```bash
npm install @microsoft/m365agentsplayground
```

#### For .NET Projects

```bash
dotnet add package Microsoft.Agents.SDK
```

#### For Python Projects

```bash
pip install microsoft-agents-sdk
```

### Step 3: Configure Environment Variables

1. Copy the environment template:

```bash
cp docs/.env.template .env
```

2. Edit `.env` and fill in your credentials:

```bash
# Azure DevOps
AZURE_DEVOPS_PAT=your_pat_token_here
AZURE_DEVOPS_ORGANIZATION=myorg
AZURE_DEVOPS_PROJECT=MyProject

# Microsoft Partner Network (if needed)
MPN_TENANT_ID=your_tenant_id
MPN_CLIENT_ID=your_client_id
MPN_CLIENT_SECRET=your_client_secret
MPN_PARTNER_ID=your_partner_id
```

3. Make sure `.env` is in your `.gitignore` file to prevent committing secrets.

### Step 4: Create Configuration File

Create a configuration file based on your needs:

#### For Azure DevOps Only

```bash
cp docs/access-management.azure-devops.example.json access-management.json
```

#### For Microsoft Partner Network Only

```bash
cp docs/access-management.mpn.example.json access-management.json
```

#### For Both Azure DevOps and MPN

```bash
cp docs/access-management.complete.example.json access-management.json
```

### Step 5: Update Configuration

Edit `access-management.json` to match your setup:

```json
{
  "version": "1.0",
  "azureDevOps": {
    "enabled": true,
    "organizationUrl": "https://dev.azure.com/YOUR_ORG",
    "projectName": "YOUR_PROJECT",
    "authentication": {
      "type": "pat",
      "token": "${AZURE_DEVOPS_PAT}"
    }
  }
}
```

## Azure DevOps Setup

### Generating a Personal Access Token (PAT)

1. Go to https://dev.azure.com/{your-organization}
2. Click on your user profile (top right) → Security
3. Click "Personal access tokens" → "New Token"
4. Configure your token:
   - Name: "M365 Agents SDK"
   - Organization: Select your organization
   - Expiration: Choose appropriate timeframe
   - Scopes: Select required scopes:
     - Work Items: Read & Write
     - Build: Read & Execute
     - Code: Read
5. Click "Create" and copy the token immediately
6. Save it in your `.env` file as `AZURE_DEVOPS_PAT`

### Testing Azure DevOps Connection

```javascript
// test-azure-devops.js
const config = require('./access-management.json');

async function testConnection() {
  const orgUrl = config.azureDevOps.organizationUrl;
  const pat = process.env.AZURE_DEVOPS_PAT;
  
  console.log(`Testing connection to ${orgUrl}...`);
  
  // Test API call
  const response = await fetch(`${orgUrl}/_apis/projects?api-version=7.0`, {
    headers: {
      'Authorization': `Basic ${Buffer.from(`:${pat}`).toString('base64')}`
    }
  });
  
  if (response.ok) {
    const projects = await response.json();
    console.log(`✓ Successfully connected! Found ${projects.count} projects.`);
  } else {
    console.error(`✗ Connection failed: ${response.statusText}`);
  }
}

testConnection();
```

## Microsoft Partner Network Setup

### Creating an Azure AD Application

1. Go to https://portal.azure.com
2. Navigate to "Azure Active Directory" → "App registrations"
3. Click "New registration"
4. Fill in the details:
   - Name: "M365 Agents MPN Integration"
   - Supported account types: "Single tenant"
   - Redirect URI: (leave blank for now)
5. Click "Register"
6. Note the "Application (client) ID" and "Directory (tenant) ID"
7. Go to "Certificates & secrets" → "New client secret"
8. Create a secret and copy it immediately
9. Save credentials in your `.env` file

### Granting Partner Center API Permissions

1. In your Azure AD app, go to "API permissions"
2. Click "Add a permission"
3. Select "APIs my organization uses"
4. Search for "Partner Center API"
5. Select delegated permissions required
6. Click "Add permissions"
7. Click "Grant admin consent" (if you have admin rights)

### Testing MPN Connection

```javascript
// test-mpn.js
const msal = require('@azure/msal-node');
const config = require('./access-management.json');

async function testMPNConnection() {
  const msalConfig = {
    auth: {
      clientId: process.env.MPN_CLIENT_ID,
      authority: `https://login.microsoftonline.com/${process.env.MPN_TENANT_ID}`,
      clientSecret: process.env.MPN_CLIENT_SECRET
    }
  };
  
  const cca = new msal.ConfidentialClientApplication(msalConfig);
  
  try {
    const result = await cca.acquireTokenByClientCredential({
      scopes: ['https://api.partnercenter.microsoft.com/.default']
    });
    
    console.log('✓ Successfully authenticated with Microsoft Partner Network!');
    console.log(`Token expires: ${new Date(result.expiresOn)}`);
  } catch (error) {
    console.error('✗ Authentication failed:', error.message);
  }
}

testMPNConnection();
```

## Security Best Practices

### 1. Never Commit Secrets

Add to your `.gitignore`:

```
.env
.env.local
access-management.json
**/secrets/
```

### 2. Use Azure Key Vault for Production

```json
{
  "credentialStore": {
    "type": "azure-keyvault",
    "vaultUrl": "https://your-vault.vault.azure.net/",
    "credentials": {
      "azureDevOpsPat": "azure-devops-pat-secret",
      "mpnClientSecret": "mpn-client-secret"
    }
  }
}
```

### 3. Rotate Credentials Regularly

Set up automatic token rotation:

```json
{
  "security": {
    "tokenRotationEnabled": true,
    "tokenRotationIntervalDays": 90
  }
}
```

### 4. Enable Audit Logging

```json
{
  "audit": {
    "enabled": true,
    "logLevel": "info",
    "destination": "azure-monitor"
  }
}
```

### 5. Limit IP Access (Production)

```json
{
  "security": {
    "allowedIpRanges": [
      "10.0.0.0/8",
      "172.16.0.0/12"
    ]
  }
}
```

## Troubleshooting

### Issue: "Authentication Failed" Error

**Symptoms**: Unable to connect to Azure DevOps or MPN

**Solutions**:
1. Verify environment variables are loaded correctly
2. Check that tokens/credentials haven't expired
3. Ensure proper scopes are configured
4. Verify network connectivity

### Issue: "Permission Denied" Error

**Symptoms**: API calls return 403 Forbidden

**Solutions**:
1. Check token scopes include required permissions
2. Verify account has necessary role assignments
3. Ensure admin consent has been granted (for MPN)

### Issue: "Rate Limit Exceeded" Error

**Symptoms**: Too many API requests

**Solutions**:
1. Implement request throttling
2. Adjust `maxRequestsPerMinute` in configuration
3. Enable retry logic with exponential backoff

## Next Steps

- Read the [full Access Management documentation](ACCESS_MANAGEMENT.md)
- Explore [sample implementations](../samples/)
- Check out [security best practices](../SECURITY.md)
- Review the [configuration schema](access-management-schema.json)

## Getting Help

- Open an issue on [GitHub](https://github.com/Microsoft/Agents/issues)
- Review [Microsoft 365 Agents SDK Docs](https://aka.ms/M365-Agents-SDK-Docs)
- Check [Azure DevOps REST API Docs](https://docs.microsoft.com/en-us/rest/api/azure/devops/)
- See [Partner Center API Docs](https://docs.microsoft.com/en-us/partner-center/develop/)
