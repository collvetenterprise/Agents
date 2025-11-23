package com.microsoft.m365agents.quickstart.models

import java.util.UUID

/**
 * Represents a message in the agent conversation.
 * 
 * @property id Unique identifier for the message
 * @property text The message content
 * @property isFromUser Whether the message is from the user (true) or agent (false)
 * @property timestamp When the message was created
 */
data class AgentMessage(
    val id: String = UUID.randomUUID().toString(),
    val text: String,
    val isFromUser: Boolean,
    val timestamp: Long = System.currentTimeMillis()
)
