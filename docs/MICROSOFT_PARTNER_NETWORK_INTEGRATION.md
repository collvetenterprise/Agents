# Microsoft Partner Network Integration Guide

This guide provides detailed instructions for integrating your Microsoft 365 Agents with Microsoft Partner Network (MPN) services.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Authentication Setup](#authentication-setup)
- [Common Use Cases](#common-use-cases)
- [API Examples](#api-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Microsoft Partner Network integration enables your agents to:

- Access partner profile information
- Manage customer relationships
- Access partner benefits and resources
- Query usage and analytics data
- Manage subscriptions and licenses
- Access marketplace offers

## Prerequisites

### Required Access

1. **Microsoft Partner Network Account**: Active Partner Center account
2. **Partner Center Access**: Appropriate role assignments
3. **Azure AD Application**: Registered app with API permissions
4. **Partner ID**: Your Microsoft Partner Network ID

### Required Roles

| Role | Purpose | Access Level |
|------|---------|--------------|
| Global Admin | Full access | All operations |
| Admin Agent | Customer management | Customer operations |
| Sales Agent | Customer relationships | Limited customer access |
| Helpdesk Agent | Support operations | Read-only customer access |

### API Scopes

- `https://api.partnercenter.microsoft.com/user_impersonation` - Access Partner Center API

## Authentication Setup

### Step 1: Register Azure AD Application

1. Navigate to [Azure Portal](https://portal.azure.com)
2. Go to Azure Active Directory → App registrations
3. Click "New registration"
4. Fill in details:
   - **Name**: "M365 Agents MPN Integration"
   - **Supported account types**: "Single tenant"
   - **Redirect URI**: Configure based on your application type

5. Note the following values:
   - Application (client) ID
   - Directory (tenant) ID

### Step 2: Create Client Secret

1. In your app registration, go to "Certificates & secrets"
2. Click "New client secret"
3. Add description and select expiration
4. Copy the secret value immediately (it won't be shown again)

### Step 3: Grant API Permissions

1. Go to "API permissions" in your app
2. Click "Add a permission"
3. Select "APIs my organization uses"
4. Search for "Microsoft Partner Center"
5. Select "user_impersonation" permission
6. Click "Grant admin consent" (requires admin privileges)

### Step 4: Configure Application

```json
{
  "microsoftPartnerNetwork": {
    "enabled": true,
    "tenantId": "your-tenant-id-here",
    "clientId": "your-client-id-here",
    "clientSecret": "${MPN_CLIENT_SECRET}",
    "partnerId": "your-partner-id-here",
    "authentication": {
      "authority": "https://login.microsoftonline.com/",
      "scopes": [
        "https://api.partnercenter.microsoft.com/user_impersonation"
      ]
    }
  }
}
```

## Common Use Cases

### Use Case 1: Partner Profile Management

**Scenario**: Agent retrieves and displays partner profile information

```javascript
async function getPartnerProfile() {
  const profile = await mpnClient.getPartnerProfile();
  
  return {
    companyName: profile.companyName,
    mpnId: profile.mpnId,
    accountType: profile.accountType,
    country: profile.defaultAddress.country
  };
}
```

### Use Case 2: Customer Management

**Scenario**: Agent manages customer relationships and subscriptions

```javascript
async function getCustomerSubscriptions(customerId) {
  const subscriptions = await mpnClient.getCustomerSubscriptions(customerId);
  
  return subscriptions.map(sub => ({
    id: sub.id,
    friendlyName: sub.friendlyName,
    quantity: sub.quantity,
    status: sub.status,
    commitmentEndDate: sub.commitmentEndDate
  }));
}
```

### Use Case 3: Benefits Access

**Scenario**: Agent retrieves available partner benefits

```javascript
async function getPartnerBenefits() {
  const benefits = await mpnClient.getPartnerBenefits();
  
  return benefits.items.filter(benefit => 
    benefit.status === 'Active' && !benefit.isExpired
  );
}
```

### Use Case 4: Usage Analytics

**Scenario**: Agent analyzes customer usage data

```javascript
async function getCustomerUsage(customerId, startDate, endDate) {
  const usage = await mpnClient.getCustomerUsageRecords(
    customerId,
    startDate,
    endDate
  );
  
  return usage.items.reduce((acc, record) => {
    acc[record.resourceName] = (acc[record.resourceName] || 0) + record.quantity;
    return acc;
  }, {});
}
```

## API Examples

### Example: Complete Partner Operations

```javascript
class MicrosoftPartnerNetworkAgent {
  constructor(config) {
    this.config = config;
    this.client = null;
  }
  
  async initialize() {
    const msalConfig = {
      auth: {
        clientId: this.config.clientId,
        authority: `${this.config.authentication.authority}${this.config.tenantId}`,
        clientSecret: this.config.clientSecret
      }
    };
    
    const cca = new msal.ConfidentialClientApplication(msalConfig);
    
    const result = await cca.acquireTokenByClientCredential({
      scopes: this.config.authentication.scopes
    });
    
    this.accessToken = result.accessToken;
    this.client = new PartnerCenterClient(this.accessToken);
  }
  
  // Get partner legal business profile
  async getBusinessProfile() {
    const endpoint = '/v1/profiles/legalbusiness';
    return await this.client.get(endpoint);
  }
  
  // Get organization profile
  async getOrganizationProfile() {
    const endpoint = '/v1/profiles/organization';
    return await this.client.get(endpoint);
  }
  
  // Update partner profile
  async updateBusinessProfile(updates) {
    const endpoint = '/v1/profiles/legalbusiness';
    return await this.client.put(endpoint, updates);
  }
  
  // Get MPN profile
  async getMpnProfile() {
    const endpoint = '/v1/profiles/mpn';
    return await this.client.get(endpoint);
  }
}
```

### Example: Customer Management

```javascript
class CustomerManagementAgent {
  constructor(mpnClient) {
    this.client = mpnClient;
  }
  
  // List all customers
  async listCustomers(size = 100) {
    const endpoint = `/v1/customers?size=${size}`;
    const response = await this.client.get(endpoint);
    return response.items;
  }
  
  // Get customer details
  async getCustomer(customerId) {
    const endpoint = `/v1/customers/${customerId}`;
    return await this.client.get(endpoint);
  }
  
  // Create new customer
  async createCustomer(customerData) {
    const endpoint = '/v1/customers';
    const payload = {
      companyProfile: {
        domain: customerData.domain,
        companyName: customerData.companyName
      },
      billingProfile: {
        email: customerData.email,
        culture: customerData.culture || 'en-US',
        language: customerData.language || 'en',
        companyName: customerData.companyName,
        defaultAddress: customerData.address
      }
    };
    
    return await this.client.post(endpoint, payload);
  }
  
  // Get customer subscriptions
  async getCustomerSubscriptions(customerId) {
    const endpoint = `/v1/customers/${customerId}/subscriptions`;
    const response = await this.client.get(endpoint);
    return response.items;
  }
  
  // Get subscription details
  async getSubscription(customerId, subscriptionId) {
    const endpoint = `/v1/customers/${customerId}/subscriptions/${subscriptionId}`;
    return await this.client.get(endpoint);
  }
  
  // Update subscription quantity
  async updateSubscriptionQuantity(customerId, subscriptionId, quantity) {
    const endpoint = `/v1/customers/${customerId}/subscriptions/${subscriptionId}`;
    const subscription = await this.getSubscription(customerId, subscriptionId);
    
    subscription.quantity = quantity;
    return await this.client.patch(endpoint, subscription);
  }
}
```

### Example: Benefits Management

```javascript
class BenefitsManagementAgent {
  constructor(mpnClient) {
    this.client = mpnClient;
  }
  
  // Get all benefits
  async getAllBenefits() {
    const endpoint = '/v1/benefits';
    const response = await this.client.get(endpoint);
    return response.items;
  }
  
  // Get active benefits
  async getActiveBenefits() {
    const benefits = await this.getAllBenefits();
    return benefits.filter(b => 
      b.status === 'Active' && 
      new Date(b.expiryDate) > new Date()
    );
  }
  
  // Get benefits by type
  async getBenefitsByType(benefitType) {
    const benefits = await this.getAllBenefits();
    return benefits.filter(b => b.benefitType === benefitType);
  }
  
  // Activate a benefit
  async activateBenefit(benefitId) {
    const endpoint = `/v1/benefits/${benefitId}/activate`;
    return await this.client.post(endpoint);
  }
  
  // Get Visual Studio subscriptions
  async getVisualStudioBenefits() {
    return await this.getBenefitsByType('VisualStudio');
  }
  
  // Get Azure credits
  async getAzureCreditBenefits() {
    return await this.getBenefitsByType('Azure');
  }
}
```

### Example: Analytics and Reporting

```javascript
class AnalyticsAgent {
  constructor(mpnClient) {
    this.client = mpnClient;
  }
  
  // Get customer usage summary
  async getCustomerUsageSummary(customerId, startDate, endDate) {
    const endpoint = `/v1/customers/${customerId}/usagerecords/resources`;
    const params = {
      start_time: startDate.toISOString(),
      end_time: endDate.toISOString()
    };
    
    const response = await this.client.get(endpoint, { params });
    return response.items;
  }
  
  // Get subscription usage
  async getSubscriptionUsage(customerId, subscriptionId, startDate, endDate) {
    const endpoint = `/v1/customers/${customerId}/subscriptions/${subscriptionId}/usagerecords`;
    const params = {
      start_time: startDate.toISOString(),
      end_time: endDate.toISOString()
    };
    
    const response = await this.client.get(endpoint, { params });
    return response;
  }
  
  // Get Azure utilization records
  async getAzureUtilization(customerId, subscriptionId, startDate, endDate) {
    const endpoint = `/v1/customers/${customerId}/subscriptions/${subscriptionId}/utilizations/azure`;
    const params = {
      start_time: startDate.toISOString(),
      end_time: endDate.toISOString(),
      granularity: 'daily'
    };
    
    const response = await this.client.get(endpoint, { params });
    return response.items;
  }
  
  // Generate monthly report
  async generateMonthlyReport(customerId) {
    const now = new Date();
    const startDate = new Date(now.getFullYear(), now.getMonth(), 1);
    const endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    
    const usage = await this.getCustomerUsageSummary(customerId, startDate, endDate);
    
    return {
      customerId,
      period: {
        start: startDate,
        end: endDate
      },
      totalResources: usage.length,
      summary: usage.map(u => ({
        resourceName: u.resourceName,
        quantity: u.quantity,
        unit: u.unit
      }))
    };
  }
}
```

### Example: Offers and Catalog

```javascript
class OffersAgent {
  constructor(mpnClient) {
    this.client = mpnClient;
  }
  
  // Get available offers
  async getOffers(country = 'US') {
    const endpoint = `/v1/offers?country=${country}`;
    const response = await this.client.get(endpoint);
    return response.items;
  }
  
  // Get offer by ID
  async getOffer(offerId, country = 'US') {
    const endpoint = `/v1/offers/${offerId}?country=${country}`;
    return await this.client.get(endpoint);
  }
  
  // Get offer categories
  async getOfferCategories(country = 'US') {
    const endpoint = `/v1/offercategories?country=${country}`;
    const response = await this.client.get(endpoint);
    return response.items;
  }
  
  // Search offers
  async searchOffers(searchTerm, country = 'US') {
    const offers = await this.getOffers(country);
    return offers.filter(offer => 
      offer.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      offer.description.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }
}
```

## Best Practices

### 1. Token Management

```javascript
class TokenManager {
  constructor(msalConfig) {
    this.cca = new msal.ConfidentialClientApplication(msalConfig);
    this.tokenCache = null;
    this.expiryTime = null;
  }
  
  async getAccessToken(scopes) {
    // Check if token is still valid
    if (this.tokenCache && this.expiryTime > Date.now() + 60000) {
      return this.tokenCache;
    }
    
    // Acquire new token
    const result = await this.cca.acquireTokenByClientCredential({ scopes });
    
    this.tokenCache = result.accessToken;
    this.expiryTime = result.expiresOn.getTime();
    
    return this.tokenCache;
  }
}
```

### 2. Error Handling

```javascript
class MpnErrorHandler {
  static async handleApiCall(apiFunction) {
    try {
      return await apiFunction();
    } catch (error) {
      if (error.statusCode === 401) {
        throw new Error('Authentication failed. Check credentials.');
      } else if (error.statusCode === 403) {
        throw new Error('Access denied. Check permissions and role assignments.');
      } else if (error.statusCode === 429) {
        throw new Error('Rate limit exceeded. Retry after delay.');
      } else if (error.statusCode === 404) {
        throw new Error('Resource not found.');
      }
      
      throw error;
    }
  }
}
```

### 3. Pagination

```javascript
async function getAllCustomers(mpnClient) {
  const allCustomers = [];
  let continuationToken = null;
  
  do {
    const params = continuationToken 
      ? { continuationToken }
      : { size: 100 };
    
    const response = await mpnClient.get('/v1/customers', { params });
    
    allCustomers.push(...response.items);
    continuationToken = response.continuationToken;
  } while (continuationToken);
  
  return allCustomers;
}
```

### 4. Caching Strategy

```javascript
class MpnCacheManager {
  constructor(cacheDurationMs = 300000) { // 5 minutes default
    this.cache = new Map();
    this.duration = cacheDurationMs;
  }
  
  get(key) {
    const cached = this.cache.get(key);
    
    if (!cached) return null;
    
    if (Date.now() - cached.timestamp > this.duration) {
      this.cache.delete(key);
      return null;
    }
    
    return cached.data;
  }
  
  set(key, data) {
    this.cache.set(key, {
      data,
      timestamp: Date.now()
    });
  }
  
  invalidate(key) {
    this.cache.delete(key);
  }
  
  clear() {
    this.cache.clear();
  }
}
```

## Troubleshooting

### Issue: Authentication Failures

**Symptoms**:
```
Error: AADSTS70011: Invalid scope
```

**Solutions**:
1. Verify application has correct API permissions
2. Ensure admin consent has been granted
3. Check tenant ID is correct
4. Verify client secret hasn't expired

### Issue: Insufficient Permissions

**Symptoms**:
```
Error: 403 Forbidden - Insufficient privileges
```

**Solutions**:
1. Verify user has required Partner Center role
2. Check application has necessary API permissions
3. Ensure partner account is active and in good standing
4. Verify MPN ID is correct

### Issue: Customer Not Found

**Symptoms**:
```
Error: 404 Not Found - Customer does not exist
```

**Solutions**:
1. Verify customer ID is correct
2. Check if customer relationship exists
3. Ensure partner has access to customer
4. Verify customer account is active

### Issue: Rate Limiting

**Symptoms**:
```
Error: 429 Too Many Requests
```

**Solutions**:
1. Implement exponential backoff
2. Add delays between requests
3. Use pagination effectively
4. Cache frequently accessed data

## Additional Resources

- [Partner Center REST API Reference](https://docs.microsoft.com/en-us/partner-center/develop/)
- [Partner Center Authentication](https://docs.microsoft.com/en-us/partner-center/develop/partner-center-authentication)
- [Partner Center Scenarios](https://docs.microsoft.com/en-us/partner-center/develop/scenarios)
- [Microsoft Partner Network](https://partner.microsoft.com/)
- [Azure AD App Registration](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
