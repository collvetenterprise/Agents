package com.microsoft.m365agents.quickstart.models

/**
 * Configuration for the M365 Agent.
 * 
 * IMPORTANT: Do not hardcode sensitive values in production.
 * Use BuildConfig, environment variables, or secure configuration management.
 * 
 * For production, consider:
 * 1. BuildConfig fields defined in build.gradle.kts
 * 2. Reading from encrypted SharedPreferences
 * 3. Fetching from a secure backend service
 * 4. Using Android Keystore for sensitive data
 */
object AgentConfig {
    /**
     * Your Microsoft 365 tenant ID.
     * Get this from Azure Portal > Azure Active Directory > Properties > Tenant ID
     * 
     * Production: Use BuildConfig.TENANT_ID or fetch from secure backend
     */
    val TENANT_ID: String
        get() = System.getenv("M365_TENANT_ID") ?: "your-tenant-id-here"
    
    /**
     * Your application client ID.
     * Register your app in Azure Portal > App Registrations
     * 
     * Production: Use BuildConfig.CLIENT_ID or fetch from secure backend
     */
    val CLIENT_ID: String
        get() = System.getenv("M365_CLIENT_ID") ?: "your-client-id-here"
    
    /**
     * Agent endpoint URL (optional for local development).
     * Point this to your deployed agent or use localhost for testing.
     * 
     * Production: Use BuildConfig.AGENT_ENDPOINT or fetch from configuration service
     */
    val AGENT_ENDPOINT: String
        get() = System.getenv("M365_AGENT_ENDPOINT") ?: "https://your-agent-endpoint.com"
    
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
