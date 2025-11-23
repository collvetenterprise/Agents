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
        // Note: This is a placeholder URL. Replace with actual repository when SDK is published
        maven {
            url = uri("https://pkgs.dev.azure.com/microsoft/_packaging/M365AgentsSDK/maven/v1")
            // Add authentication if required
            // credentials {
            //     username = System.getenv("AZURE_ARTIFACTS_USERNAME")
            //     password = System.getenv("AZURE_ARTIFACTS_PASSWORD")
            // }
        }
    }
}

rootProject.name = "M365 Agent Quickstart"
include(":app")
