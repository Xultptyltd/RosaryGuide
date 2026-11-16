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
    }
}

rootProject.name = "RosaryGuide-Android"

include(
    ":app",
    ":core:model",
    ":core:data",
    ":core:designsystem",
    ":feature:onboarding",
    ":feature:today",
    ":feature:learn",
    ":feature:feasts",
    ":feature:profile",
    ":feature:pray",
    ":feature:settings",
    ":sync",
    ":notifications",
)
