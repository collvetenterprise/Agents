# Azure DevOps Integration Guide

This guide provides detailed instructions for integrating your Microsoft 365 Agents with Azure DevOps services.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Authentication Methods](#authentication-methods)
- [Common Use Cases](#common-use-cases)
- [API Examples](#api-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Azure DevOps integration enables your agents to:

- Query and update work items
- Trigger build pipelines
- Monitor release status
- Access code repositories
- Create and manage pull requests
- Track testing results

## Prerequisites

### Required Access

1. **Azure DevOps Account**: Active account with appropriate permissions
2. **Organization Access**: Member or contributor access to the organization
3. **Project Permissions**: Permissions in the target project(s)

### Required Scopes

| Scope | Purpose | Access Level |
|-------|---------|--------------|
| `vso.work` | Read work items | Read |
| `vso.work_write` | Modify work items | Write |
| `vso.build` | View builds | Read |
| `vso.build_execute` | Queue builds | Execute |
| `vso.code` | Read repositories | Read |
| `vso.code_write` | Create/update code | Write |
| `vso.release` | View releases | Read |
| `vso.release_execute` | Trigger releases | Execute |

## Authentication Methods

### Method 1: Personal Access Token (PAT)

**Best for**: Individual developers, testing, and small teams

1. Generate a PAT in Azure DevOps
2. Store securely in environment variables
3. Configure in your access management settings

```json
{
  "azureDevOps": {
    "authentication": {
      "type": "pat",
      "token": "${AZURE_DEVOPS_PAT}"
    }
  }
}
```

### Method 2: OAuth 2.0

**Best for**: Production applications, multi-user scenarios

1. Register an application in Azure AD
2. Configure OAuth flow
3. Handle token refresh

```json
{
  "azureDevOps": {
    "authentication": {
      "type": "oauth",
      "clientId": "${AZURE_AD_CLIENT_ID}",
      "clientSecret": "${AZURE_AD_CLIENT_SECRET}",
      "tenantId": "${AZURE_AD_TENANT_ID}"
    }
  }
}
```

### Method 3: Managed Identity

**Best for**: Azure-hosted applications, serverless functions

```json
{
  "azureDevOps": {
    "authentication": {
      "type": "managed-identity"
    }
  }
}
```

## Common Use Cases

### Use Case 1: Work Item Management

**Scenario**: Agent creates work items based on user requests

```javascript
async function createWorkItem(title, description, type = 'Task') {
  const workItem = {
    op: 'add',
    path: '/fields/System.Title',
    value: title
  };
  
  const response = await azureDevOpsClient.createWorkItem(
    project,
    type,
    [workItem]
  );
  
  return response;
}
```

### Use Case 2: Build Pipeline Automation

**Scenario**: Agent triggers builds based on events

```javascript
async function triggerBuild(pipelineId, sourceBranch) {
  const build = await azureDevOpsClient.queueBuild({
    definition: { id: pipelineId },
    sourceBranch: sourceBranch,
    parameters: JSON.stringify({
      customParameter: 'value'
    })
  });
  
  return build;
}
```

### Use Case 3: Pull Request Management

**Scenario**: Agent monitors and interacts with pull requests

```javascript
async function reviewPullRequest(pullRequestId, vote, comment) {
  await azureDevOpsClient.createPullRequestReview({
    pullRequestId: pullRequestId,
    vote: vote, // 10 = approved, 5 = approved with suggestions, 0 = no vote, -5 = waiting, -10 = rejected
    content: comment
  });
}
```

### Use Case 4: Query Work Items

**Scenario**: Agent retrieves work items based on criteria

```javascript
async function getActiveWorkItems() {
  const wiql = {
    query: `
      SELECT [System.Id], [System.Title], [System.State]
      FROM WorkItems
      WHERE [System.State] = 'Active'
      AND [System.AssignedTo] = @Me
      ORDER BY [System.CreatedDate] DESC
    `
  };
  
  const result = await azureDevOpsClient.queryByWiql(wiql);
  return result.workItems;
}
```

## API Examples

### Example: Complete Work Item Operations

```javascript
class AzureDevOpsWorkItemAgent {
  constructor(config) {
    this.client = new AzureDevOpsClient(config);
    this.project = config.projectName;
  }
  
  // Create a bug
  async createBug(title, description, severity) {
    const document = [
      {
        op: 'add',
        path: '/fields/System.Title',
        value: title
      },
      {
        op: 'add',
        path: '/fields/System.Description',
        value: description
      },
      {
        op: 'add',
        path: '/fields/Microsoft.VSTS.Common.Severity',
        value: severity
      }
    ];
    
    return await this.client.createWorkItem(this.project, 'Bug', document);
  }
  
  // Update work item state
  async updateWorkItemState(workItemId, state, comment) {
    const document = [
      {
        op: 'add',
        path: '/fields/System.State',
        value: state
      },
      {
        op: 'add',
        path: '/fields/System.History',
        value: comment
      }
    ];
    
    return await this.client.updateWorkItem(workItemId, document);
  }
  
  // Get work item details
  async getWorkItem(workItemId, fields = null) {
    const params = fields ? { fields: fields.join(',') } : {};
    return await this.client.getWorkItem(workItemId, params);
  }
  
  // Link related work items
  async linkWorkItems(sourceId, targetId, linkType = 'System.LinkTypes.Related') {
    const document = [
      {
        op: 'add',
        path: '/relations/-',
        value: {
          rel: linkType,
          url: `${this.client.organizationUrl}/${this.project}/_apis/wit/workItems/${targetId}`
        }
      }
    ];
    
    return await this.client.updateWorkItem(sourceId, document);
  }
}
```

### Example: Build Pipeline Integration

```javascript
class AzureDevOpsBuildAgent {
  constructor(config) {
    this.client = new AzureDevOpsClient(config);
    this.project = config.projectName;
  }
  
  // Queue a new build
  async queueBuild(definitionId, branch = 'main', parameters = {}) {
    const build = {
      definition: { id: definitionId },
      sourceBranch: `refs/heads/${branch}`,
      parameters: JSON.stringify(parameters)
    };
    
    return await this.client.queueBuild(this.project, build);
  }
  
  // Get build status
  async getBuildStatus(buildId) {
    return await this.client.getBuild(this.project, buildId);
  }
  
  // Wait for build completion
  async waitForBuild(buildId, timeoutMs = 300000) {
    const startTime = Date.now();
    
    while (Date.now() - startTime < timeoutMs) {
      const build = await this.getBuildStatus(buildId);
      
      if (build.status === 'completed') {
        return build;
      }
      
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
    
    throw new Error('Build timeout');
  }
  
  // Get build logs
  async getBuildLogs(buildId) {
    const logs = await this.client.getBuildLogs(this.project, buildId);
    return logs;
  }
}
```

### Example: Repository Operations

```javascript
class AzureDevOpsRepoAgent {
  constructor(config) {
    this.client = new AzureDevOpsClient(config);
    this.project = config.projectName;
  }
  
  // Get file contents
  async getFileContent(repositoryId, path, branch = 'main') {
    const item = await this.client.getItem(
      this.project,
      repositoryId,
      path,
      { versionDescriptor: { version: branch } }
    );
    
    return item.content;
  }
  
  // Create a pull request
  async createPullRequest(repositoryId, sourceBranch, targetBranch, title, description) {
    const pullRequest = {
      sourceRefName: `refs/heads/${sourceBranch}`,
      targetRefName: `refs/heads/${targetBranch}`,
      title: title,
      description: description
    };
    
    return await this.client.createPullRequest(
      this.project,
      repositoryId,
      pullRequest
    );
  }
  
  // Get commits
  async getCommits(repositoryId, branch = 'main', top = 10) {
    return await this.client.getCommits(
      this.project,
      repositoryId,
      { searchCriteria: { itemVersion: { version: branch }, $top: top } }
    );
  }
}
```

## Best Practices

### 1. Rate Limiting

Implement proper rate limiting to avoid throttling:

```javascript
class RateLimiter {
  constructor(maxRequestsPerMinute = 60) {
    this.maxRequests = maxRequestsPerMinute;
    this.requests = [];
  }
  
  async throttle() {
    const now = Date.now();
    this.requests = this.requests.filter(time => now - time < 60000);
    
    if (this.requests.length >= this.maxRequests) {
      const oldestRequest = this.requests[0];
      const waitTime = 60000 - (now - oldestRequest);
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }
    
    this.requests.push(now);
  }
}
```

### 2. Error Handling

```javascript
async function safeApiCall(apiFunction, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      return await apiFunction();
    } catch (error) {
      if (error.statusCode === 429) {
        // Rate limited - wait and retry
        const retryAfter = error.headers['retry-after'] || Math.pow(2, i);
        await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
      } else if (i === retries - 1) {
        throw error;
      }
    }
  }
}
```

### 3. Caching

Cache frequently accessed data:

```javascript
class CachedAzureDevOpsClient {
  constructor(client, cacheDurationMs = 60000) {
    this.client = client;
    this.cache = new Map();
    this.cacheDuration = cacheDurationMs;
  }
  
  async getWorkItemCached(id) {
    const cacheKey = `workitem-${id}`;
    const cached = this.cache.get(cacheKey);
    
    if (cached && Date.now() - cached.timestamp < this.cacheDuration) {
      return cached.data;
    }
    
    const data = await this.client.getWorkItem(id);
    this.cache.set(cacheKey, { data, timestamp: Date.now() });
    return data;
  }
}
```

### 4. Logging and Monitoring

```javascript
class AuditedAzureDevOpsClient {
  constructor(client, logger) {
    this.client = client;
    this.logger = logger;
  }
  
  async createWorkItem(project, type, document) {
    this.logger.info('Creating work item', { project, type });
    
    try {
      const result = await this.client.createWorkItem(project, type, document);
      this.logger.info('Work item created', { id: result.id });
      return result;
    } catch (error) {
      this.logger.error('Failed to create work item', { error: error.message });
      throw error;
    }
  }
}
```

## Troubleshooting

### Issue: PAT Authentication Fails

**Symptoms**:
```
Error: 401 Unauthorized
```

**Solutions**:
1. Verify PAT hasn't expired
2. Check PAT has required scopes
3. Ensure PAT is correctly formatted in Base64
4. Verify organization URL is correct

### Issue: Permission Denied on Operations

**Symptoms**:
```
Error: 403 Forbidden - TF400813: Resource not available for anonymous access
```

**Solutions**:
1. Verify account has required permissions in project
2. Check if project requires specific security group membership
3. Ensure PAT scopes match required permissions

### Issue: Rate Limiting

**Symptoms**:
```
Error: 429 Too Many Requests
```

**Solutions**:
1. Implement exponential backoff
2. Reduce request frequency
3. Use batch operations where possible
4. Respect `Retry-After` header

### Issue: Work Item Query Failures

**Symptoms**:
```
Error: Invalid WIQL query
```

**Solutions**:
1. Validate WIQL syntax
2. Check field names are correct
3. Ensure proper escaping of values
4. Test query in Azure DevOps UI first

## Additional Resources

- [Azure DevOps REST API Reference](https://docs.microsoft.com/en-us/rest/api/azure/devops/)
- [Work Item Tracking API](https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/)
- [Build API](https://docs.microsoft.com/en-us/rest/api/azure/devops/build/)
- [Git API](https://docs.microsoft.com/en-us/rest/api/azure/devops/git/)
- [WIQL Syntax Reference](https://docs.microsoft.com/en-us/azure/devops/boards/queries/wiql-syntax)
