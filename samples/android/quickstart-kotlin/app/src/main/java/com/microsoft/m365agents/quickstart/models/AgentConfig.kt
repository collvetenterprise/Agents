package com.microsoft.m365agents.quickstart.models

/**
 * Configuration for the M365 Agent.
 * 
 * Update these values with your actual configuration.
 */
object AgentConfig {
    /**
     * Your Microsoft 365 tenant ID.
     * Get this from Azure Portal > Azure Active Directory > Properties > Tenant ID
     */
    const val TENANT_ID = "your-tenant-id-here"
    
    /**
     * Your application client ID.
     * Register your app in Azure Portal > App Registrations
     */
    const val CLIENT_ID = "your-client-id-here"
    
    /**
     * Agent endpoint URL (optional for local development).
     * Point this to your deployed agent or use localhost for testing.
     */
    const val AGENT_ENDPOINT = "https://your-agent-endpoint.com"
    
    /**
     * Enable GitHub Copilot integration.
     * Requires GitHub Copilot subscription.
     */
    const val ENABLE_COPILOT = true
    
    /**
     * Enable Model Context Protocol (MCP) support.
     * Provides context-aware AI interactions.
     */
    const val ENABLE_MCP = true
    
    /**
     * Enable enterprise features (multi-tenant, enhanced security, etc.).
     */
    const val ENABLE_ENTERPRISE_FEATURES = true
    
    /**
     * Enable offline mode.
     * Messages will be queued when offline and sent when connection is restored.
     */
    const val ENABLE_OFFLINE_MODE = true
    
    /**
     * Maximum number of messages to keep in memory.
     */
    const val MAX_MESSAGES_IN_MEMORY = 100
    
    /**
     * Request timeout in seconds.
     */
    const val REQUEST_TIMEOUT_SECONDS = 30L
}
