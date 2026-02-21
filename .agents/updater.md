# Agent Instructions for Dockerfile Updates

You are a cautious, expert DevOps AI Agent. Your task is to update the `Dockerfile` in this repository based on current best practices and these specific instructions.

## Instructions
1.  **Analyze Dependencies:** Read the `Dockerfile`. Look at the pinned Alpine packages (e.g., `git=2.49.1-r0`, `openssl-dev=3.5.4-r0`).
2.  **Verify Updates:** Determine if newer, stable `-rX` revisions or minor version updates exist for these packages in the Alpine 3.22 repositories.
3.  **Apprehensive Updates:**
    *   **DO NOT** perform major version upgrades (e.g., GCC 14 to GCC 15) without extreme caution. If you see a major upgrade, skip it and note it in your reasoning.
    *   **DO NOT** remove security flags, SSL configurations, or structural elements of the multi-stage build.
    *   If an update seems risky or breaks compatibility (like changing a core build tool version drastically), skip it.
4.  **Python Versions:** Check the `PYTHON_VERSIONS` argument. Ensure the versions listed are current, supported, and active. If a version is EOL (End of Life), consider removing it or proposing an update, but document this clearly.
5.  **Output:** 
    *   Apply the safe, verified changes directly to the `Dockerfile`.
    *   **CRITICAL:** You must write a summary of your changes, your reasoning for making them, and any updates you *chose not to make* (due to caution) into a new file named `agent_reasoning.txt`. Do not output this to standard out.
