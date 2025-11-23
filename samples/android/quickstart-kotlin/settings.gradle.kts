pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // Add Microsoft Maven repository for M365 Agents SDK
        maven {
            url = uri("https://pkgs.dev.azure.com/microsoft/_packaging/M365AgentsSDK/maven/v1")
        }
    }
}

rootProject.name = "M365 Agent Quickstart"
include(":app")
